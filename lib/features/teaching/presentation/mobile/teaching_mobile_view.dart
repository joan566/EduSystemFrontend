import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mobile/mobile_brand_bar.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_header_action.dart';
import '../../../../core/widgets/mobile/mobile_select_field.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../../academic_periods/presentation/providers/academic_periods_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../subjects/presentation/providers/subjects_provider.dart';
import '../providers/teaching_provider.dart';
import '../shared/class_grouping.dart';
import '../shared/class_lookup.dart';
import '../shared/add_classes_form_loader.dart';
import '../shared/teaching_actions.dart';
import 'widgets/course_classes_card.dart';

/// Mobile "Clases": the teacher's courses, each with the subjects taught in
/// it, for one academic period. Search, a subject filter (chips) and an
/// active-state filter narrow the list; a subject opens its class.
class TeachingMobileView extends StatelessWidget {
  const TeachingMobileView({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.academicPeriodId,
    required this.onAcademicPeriodChanged,
    required this.search,
    required this.onSearchChanged,
  });

  final AssignmentFilters filters;
  final ValueChanged<AssignmentFilters> onFiltersChanged;
  final int? academicPeriodId;
  final ValueChanged<int?> onAcademicPeriodChanged;
  final String search;
  final ValueChanged<String> onSearchChanged;

  Future<void> _addClasses(BuildContext context, {int? groupId}) =>
      showMobileForm<void>(
        context,
        child: AddClassesFormLoader(
          initialGroupId: groupId,
          initialAcademicPeriodId: academicPeriodId,
          onSubmit: (data) => TeachingActions.addClasses(context, data),
        ),
      );

  Future<void> _openActions(
    BuildContext context,
    ClassEntry entry,
    AcademicPeriodEntity? academicPeriod,
  ) async {
    final a = entry.assignment;
    final period = entry.period;
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                a.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (period == null && academicPeriod != null)
              ListTile(
                leading: const Icon(Icons.add),
                title: Text('Crear clase en ${academicPeriod.name}'),
                onTap: () => Navigator.of(context).pop(0),
              ),
            ListTile(
              leading: Icon(
                a.active ? Icons.toggle_off_outlined : Icons.toggle_on,
              ),
              title: Text(
                a.active ? 'Marcar como inactiva' : 'Marcar como activa',
              ),
              onTap: () => Navigator.of(context).pop(1),
            ),
            if (period != null)
              ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: Text('Eliminar clase de ${period.academicPeriodName}'),
                onTap: () => Navigator.of(context).pop(2),
              ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Quitar materia del curso'),
              onTap: () => Navigator.of(context).pop(3),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 0:
        await TeachingActions.createClassFor(
          context,
          assignment: a,
          academicPeriod: academicPeriod!,
        );
      case 1:
        await TeachingActions.setAssignmentActive(context, a, !a.active);
      case 2:
        await TeachingActions.deletePeriod(context, period!);
      case 3:
        await TeachingActions.deleteAssignment(context, a);
    }
  }

  Future<void> _openStatusFilter(BuildContext context) async {
    final picked = await showMobileSheet<({bool? active})>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Estado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final (value, label) in const [
              (null, 'Todas'),
              (true, 'Activas'),
              (false, 'Inactivas'),
            ])
              ListTile(
                title: Text(label),
                trailing: filters.active == value
                    ? const Icon(Icons.check, color: AppColors.accentBlue)
                    : null,
                onTap: () => Navigator.of(context).pop((active: value)),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    onFiltersChanged(
      AssignmentFilters(subjectId: filters.subjectId, active: picked.active),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teaching = context.watch<TeachingProvider>();
    final academicPeriods = context
        .watch<AcademicPeriodsProvider>()
        .state
        .items;
    final subjects = context.watch<SubjectsProvider>().state.items;
    final weekly = context
        .watch<ScheduleProvider>()
        .week
        .data
        ?.occurrencesByTeachingPeriod;
    final academicPeriod = academicPeriods
        .where((p) => p.id == academicPeriodId)
        .firstOrNull;
    final textTheme = Theme.of(context).textTheme;

    String? description(int subjectId) =>
        subjects.where((s) => s.id == subjectId).firstOrNull?.description;

    final grouping = groupClasses(
      assignments: teaching.allAssignments,
      periods: teaching.allPeriods,
      academicPeriodId: academicPeriodId,
      include: (entry, courseLabel) =>
          (filters.subjectId == null || entry.subjectId == filters.subjectId) &&
          (filters.active == null ||
              entry.assignment.active == filters.active) &&
          matchesSearch(search, [
            entry.subjectName,
            courseLabel,
            entry.assignment.gradeName,
            description(entry.subjectId),
          ]),
    );
    final taughtSubjects =
        {
          for (final a in teaching.allAssignments) a.subjectId: a.subjectName,
        }.entries.toList()..sort(
          (a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()),
        );
    final loading = switch (teaching.assignmentsState.status) {
      ViewStatus.initial || ViewStatus.loading => true,
      _ =>
        teaching.allPeriods.isEmpty &&
            switch (teaching.periodsState.status) {
              ViewStatus.initial || ViewStatus.loading => true,
              _ => false,
            },
    };
    final single = grouping.singleSubjectName;
    final summary = loading
        ? ''
        : single != null
        ? '$single  ·  ${_count(grouping.courseCount, 'curso', 'cursos')}'
        : '${_count(grouping.courseCount, 'curso', 'cursos')}  ·  '
              '${_count(grouping.classCount, 'clase', 'clases')}';

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MobileBrandBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clases',
                        style: textTheme.headlineLarge?.copyWith(fontSize: 26),
                      ),
                      Text(
                        summary,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                MobileHeaderAction(
                  icon: Icons.add,
                  tooltip: 'Agregar materias a un curso',
                  onPressed: () => _addClasses(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchField(
                    hint: 'Buscar curso o materia...',
                    initialValue: search,
                    onChanged: onSearchChanged,
                  ),
                ),
                const SizedBox(width: 10),
                _StatusFilterButton(
                  active: filters.active != null,
                  onPressed: () => _openStatusFilter(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: MobileSelectField<AcademicPeriodEntity?>(
              icon: Icons.calendar_month_outlined,
              label: 'Periodo',
              value: academicPeriod,
              options: [null, ...academicPeriods],
              itemLabel: (p) => p?.name ?? 'Todos los periodos',
              onChanged: (p) => onAcademicPeriodChanged(p?.id),
            ),
          ),
          if (taughtSubjects.length > 1)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                children: [
                  for (final (id, name) in [
                    (null, 'Todas'),
                    for (final s in taughtSubjects) (s.key, s.value),
                  ]) ...[
                    ChoiceChip(
                      label: Text(name),
                      selected: filters.subjectId == id,
                      showCheckmark: false,
                      selectedColor: AppColors.accentBlue.withValues(
                        alpha: 0.12,
                      ),
                      labelStyle: textTheme.labelLarge?.copyWith(
                        color: filters.subjectId == id
                            ? AppColors.accentBlue
                            : null,
                      ),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => onFiltersChanged(
                        AssignmentFilters(
                          subjectId: id,
                          active: filters.active,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: loading
                ? const _CoursesSkeleton()
                : switch (teaching.assignmentsState.status) {
                    ViewStatus.error => AppErrorState(
                      exception: teaching.assignmentsState.error!,
                      onRetry: () =>
                          context.read<TeachingProvider>().refreshAssignments(),
                    ),
                    ViewStatus.empty => AppEmptyState(
                      title: 'Aún no tienes clases',
                      message:
                          'Agrega las materias que dictas en cada curso para '
                          'empezar.',
                      icon: Icons.groups_outlined,
                      actionLabel: 'Agregar materias',
                      onAction: () => _addClasses(context),
                    ),
                    _ when grouping.isEmpty => const AppEmptyState(
                      title: 'Sin resultados',
                      message:
                          'Ningún curso o materia coincide con los filtros.',
                      icon: Icons.search_off,
                    ),
                    _ => _CourseList(
                      grouping: grouping,
                      academicPeriod: academicPeriod,
                      weekly: weekly,
                      onOpen: (entry) => context.push(
                        RoutePaths.teachingPeriodDetail(entry.period!.id),
                      ),
                      onCreateClass: (entry) => TeachingActions.createClassFor(
                        context,
                        assignment: entry.assignment,
                        academicPeriod: academicPeriod!,
                      ),
                      onActions: (entry) =>
                          _openActions(context, entry, academicPeriod),
                      onAddSubject: (groupId) =>
                          _addClasses(context, groupId: groupId),
                    ),
                  },
          ),
        ],
      ),
    );
  }
}

String _count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

class _CourseList extends StatelessWidget {
  const _CourseList({
    required this.grouping,
    required this.academicPeriod,
    required this.weekly,
    required this.onOpen,
    required this.onCreateClass,
    required this.onActions,
    required this.onAddSubject,
  });

  final ClassGrouping grouping;
  final AcademicPeriodEntity? academicPeriod;
  final Map<int, int>? weekly;
  final ValueChanged<ClassEntry> onOpen;
  final ValueChanged<ClassEntry> onCreateClass;
  final ValueChanged<ClassEntry> onActions;
  final ValueChanged<int> onAddSubject;

  @override
  Widget build(BuildContext context) {
    final compact = grouping.singleSubjectName != null;
    // A grade header only helps when it groups several courses.
    final gradeHeaders = grouping.sections.any((s) => s.courses.length > 1);
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        for (final section in grouping.sections) ...[
          if (gradeHeaders)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text(
                section.gradeName,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          for (final course in section.courses) ...[
            CourseClassesCard(
              course: course,
              academicPeriod: academicPeriod,
              weeklySessions: weekly,
              compact: compact,
              onOpen: onOpen,
              onCreateClass: onCreateClass,
              onActions: onActions,
              onAddSubject: () => onAddSubject(course.groupId),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

/// Course cards being read: a header line and two subject rows each.
class _CoursesSkeleton extends StatelessWidget {
  const _CoursesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 3; i++) ...[
            SkeletonSurface(
              radius: 14,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 90.0 + i * 20, height: 16),
                  const SizedBox(height: 16),
                  for (var j = 0; j < 2; j++) ...[
                    if (j > 0) const SizedBox(height: 14),
                    SkeletonTile(
                      leading: SkeletonLeading.square,
                      leadingSize: 40,
                      titleFactor: SkeletonRepeat.factor(i + j),
                      subtitleFactor: 0.4,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StatusFilterButton extends StatelessWidget {
  const _StatusFilterButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Badge(
      isLabelVisible: active,
      smallSize: 8,
      backgroundColor: AppColors.accentBlue,
      child: IconButton.outlined(
        tooltip: 'Filtrar por estado',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          side: BorderSide(color: colors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.tune),
      ),
    );
  }
}
