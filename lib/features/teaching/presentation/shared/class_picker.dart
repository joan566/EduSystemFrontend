import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../../academic_periods/presentation/providers/academic_periods_provider.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';
import 'class_grouping.dart';
import 'class_lookup.dart';

/// The class a module opens on: the requested one ([preferredId], from
/// `?teachingPeriodId=`), else [suggestedId] (e.g. the next class today),
/// else the last one used this session, else the first of the running
/// academic period, else any. Null when the teacher has no classes.
Future<TeachingPeriodEntity?> initialClass(
  BuildContext context, {
  int? preferredId,
  int? suggestedId,
}) async {
  final teaching = context.read<TeachingProvider>();
  final academicPeriods = context.read<AcademicPeriodsProvider>();
  await Future.wait([
    teaching.ensureAllPeriodsLoaded(),
    academicPeriods.ensure(),
  ]);
  final all = teaching.allPeriods;
  TeachingPeriodEntity? byId(int? id) =>
      id == null ? null : all.where((p) => p.id == id).firstOrNull;
  final current = defaultAcademicPeriod(academicPeriods.all);
  final inCurrent = [
    for (final p in all)
      if (current == null || p.academicPeriodId == current.id) p,
  ];
  final picked =
      byId(preferredId) ??
      byId(suggestedId) ??
      byId(teaching.lastClassId) ??
      groupPeriodsByCourse(inCurrent).firstOrNull?.classes.first ??
      all.firstOrNull;
  if (picked != null) teaching.rememberClass(picked.id);
  return picked;
}

/// [period]'s name where the screen is about the running academic period:
/// "Matemáticas · 6° A", plus the period only when it isn't the running
/// one.
String classPickerLabel(BuildContext context, TeachingPeriodEntity period) {
  final current = defaultAcademicPeriod(
    context.watch<AcademicPeriodsProvider>().all,
  );
  return period.academicPeriodId == current?.id
      ? period.title
      : period.displayName;
}

/// Every module's class picker: the teacher's classes of the running
/// academic period (or all of them) by course, searchable. Picking pops the
/// [TeachingPeriodEntity] and remembers it for the other modules.
///
/// Platform-agnostic content in an [AppFormFrame]: mobile shows it in a
/// sheet, desktop in a dialog.
class ClassPickerContent extends StatefulWidget {
  const ClassPickerContent({super.key, this.selectedId});

  final int? selectedId;

  @override
  State<ClassPickerContent> createState() => _ClassPickerContentState();
}

class _ClassPickerContentState extends State<ClassPickerContent> {
  String _search = '';

  /// Null until the teacher toggles it: then the scope follows the
  /// selected class (all periods when it isn't of the running one).
  bool? _allPeriods;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TeachingProvider>().ensureAllPeriodsLoaded();
      context.read<AcademicPeriodsProvider>().ensure();
    });
  }

  void _pick(TeachingPeriodEntity period) {
    context.read<TeachingProvider>().rememberClass(period.id);
    Navigator.of(context).pop(period);
  }

  @override
  Widget build(BuildContext context) {
    final teaching = context.watch<TeachingProvider>();
    final current = defaultAcademicPeriod(
      context.watch<AcademicPeriodsProvider>().all,
    );
    final textTheme = Theme.of(context).textTheme;
    final all = teaching.allPeriods;
    final selected = all.where((p) => p.id == widget.selectedId).firstOrNull;
    final hasOtherPeriods =
        current != null && all.any((p) => p.academicPeriodId != current.id);
    final allPeriods =
        current == null ||
        (_allPeriods ??
            (selected != null && selected.academicPeriodId != current.id));
    final visible = [
      for (final p in all)
        if ((allPeriods || p.academicPeriodId == current.id) &&
            matchesSearch(_search, [
              p.subjectName,
              p.courseLabel,
              p.academicPeriodName,
            ]))
          p,
    ];
    final courses = groupPeriodsByCourse(visible);
    final subjects = {for (final p in visible) p.subjectId};
    final singleSubject = subjects.length == 1 && courses.length > 1;
    final loading =
        all.isEmpty &&
        switch (teaching.periodsState.status) {
          ViewStatus.initial || ViewStatus.loading => true,
          _ => false,
        };

    String subtitle(TeachingPeriodEntity p) => [
      if (p.academicPeriodId != current?.id) p.academicPeriodName,
      '${p.studentCount} estudiantes',
    ].join(' · ');

    return AppFormFrame(
      title: 'Elegir clase',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (all.length > 6) ...[
            AppSearchField(
              hint: 'Buscar curso o materia...',
              initialValue: _search,
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 12),
          ],
          if (current != null && hasOtherPeriods) ...[
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(current.name)),
                const ButtonSegment(
                  value: true,
                  label: Text('Todos los periodos'),
                ),
              ],
              selected: {allPeriods},
              onSelectionChanged: (value) =>
                  setState(() => _allPeriods = value.first),
            ),
            const SizedBox(height: 12),
          ],
          if (loading)
            const SkeletonTileList(count: 4, padding: EdgeInsets.all(4))
          else if (all.isEmpty)
            _Message('Todavía no tienes clases.')
          else if (visible.isEmpty)
            _Message(
              _search.isEmpty
                  ? 'Sin clases en ${current?.name ?? 'este periodo'}.'
                  : 'Ninguna clase coincide con la búsqueda.',
            )
          else ...[
            if (singleSubject)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: Text(
                  '${visible.first.subjectName} · ${courses.length} cursos',
                  style: textTheme.bodySmall,
                ),
              ),
            for (final course in courses) ...[
              if (!singleSubject)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                  child: Text(
                    course.label,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              for (final p in course.classes)
                _ClassOption(
                  period: p,
                  title: singleSubject ? course.label : p.subjectName,
                  subtitle: subtitle(p),
                  selected: p.id == widget.selectedId,
                  onTap: () => _pick(p),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}

class _ClassOption extends StatelessWidget {
  const _ClassOption({
    required this.period,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final TeachingPeriodEntity period;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected
          ? AppColors.accentBlue.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              TintedIcon(
                icon: subjectIcon(period.subjectName),
                color: subjectAccent(period.subjectId),
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    Text(subtitle, style: textTheme.bodySmall),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.accentBlue),
            ],
          ),
        ),
      ),
    );
  }
}
