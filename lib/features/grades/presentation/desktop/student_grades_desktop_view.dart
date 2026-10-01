import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../providers/gradebook_provider.dart';
import '../shared/category_visuals.dart';
import '../shared/grade_labels.dart';
import '../shared/grade_ring.dart';
import 'widgets/grade_entries_table.dart';

/// Desktop student grades: breadcrumb and actions, the student; a side
/// column with the final grade, each component and an inline-editable
/// observation; the evaluations table (filterable by component) beside it.
class StudentGradesDesktopView extends StatelessWidget {
  const StudentGradesDesktopView({
    super.key,
    required this.teachingPeriodId,
    required this.studentId,
    required this.onRefresh,
  });

  final int teachingPeriodId;
  final int studentId;
  final Future<void> Function() onRefresh;

  static const _railWidth = 340.0;
  static const _railBesideMinWidth = 1080.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GradebookProvider>().report(
      teachingPeriodId,
      studentId,
    );
    final report = state.data;

    return Scaffold(
      body: switch (state.status) {
        DetailStatus.error => AppErrorState(
          exception: state.error!,
          onRetry: onRefresh,
        ),
        _ when report == null => const DesktopDetailSkeleton(
          rail: 3,
          railEnd: true,
          main: DesktopListTableSkeleton(
            root: false,
            shrinkWrap: true,
            columns: [
              SkeletonColumn('Evaluación', flex: 5, cell: SkeletonCell.badge),
              SkeletonColumn('Componente', flex: 2),
              SkeletonColumn('Peso', flex: 1, cell: SkeletonCell.value),
              SkeletonColumn('Nota', flex: 3, cell: SkeletonCell.bar),
              SkeletonColumn(
                'Aporte',
                flex: 1,
                cell: SkeletonCell.value,
                alignEnd: true,
              ),
            ],
          ),
        ),
        _ => LayoutBuilder(
          builder: (context, constraints) {
            final beside = constraints.maxWidth >= _railBesideMinWidth;
            final rail = [
              _SummaryCard(report: report),
              if (report.categories.isNotEmpty) _ComponentsCard(report: report),
              _ObservationCard(
                key: ValueKey(report.observation?.text),
                report: report,
              ),
            ];
            final table = GradeEntriesTable(report: report);
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                _Header(report: report, onRefresh: onRefresh),
                const SizedBox(height: 24),
                if (beside)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _railWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, card) in rail.indexed) ...[
                              if (i > 0) const SizedBox(height: 16),
                              card,
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: table),
                    ],
                  )
                else ...[
                  for (final card in rail) ...[
                    card,
                    const SizedBox(height: 16),
                  ],
                  table,
                ],
              ],
            );
          },
        ),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.report, required this.onRefresh});

  final StudentGradeReport report;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final student = report.student;
    final period = context
        .watch<TeachingProvider>()
        .allPeriods
        .where((p) => p.id == report.teachingPeriodId)
        .firstOrNull;
    final classLabel = period?.title;

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppButton(
          label: 'Ficha del estudiante',
          icon: Icons.person_outline,
          variant: AppButtonVariant.outlined,
          onPressed: () => context.push(RoutePaths.studentDetail(student.id)),
        ),
        AppButton(
          label: 'Configurar pesos',
          icon: Icons.tune,
          variant: AppButtonVariant.outlined,
          // Saving weights there makes this report stale; it is re-read on
          // return only then.
          onPressed: () => context.push(
            RoutePaths.gradingSettingsForClass(report.teachingPeriodId),
          ),
        ),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Navigator.of(context).canPop()
                      ? Navigator.of(context).pop()
                      : context.go(
                          RoutePaths.gradesForClass(report.teachingPeriodId),
                        ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          size: 16,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Calificaciones',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (classLabel != null) ...[
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: textTheme.bodySmall?.color,
                  ),
                  Flexible(
                    child: Text(
                      classLabel,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
                if (wide) ...[
                  const SizedBox(width: 16),
                  Expanded(child: actions),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.accentBlue,
                  child: Text(
                    student.initials,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              student.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GradeStatusChip(
                            passing: report.passing,
                            hasGrade: report.periodGrade != null,
                          ),
                        ],
                      ),
                      Text(
                        [
                          'Código ${student.studentCode}',
                          ?classLabel,
                          if (period != null) period.academicPeriodName,
                        ].join('  ·  '),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!wide) ...[const SizedBox(height: 14), actions],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final StudentGradeReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final scale = report.scale;
    final grade = report.periodGrade;

    if (!report.configurationComplete) {
      return DesktopSectionCard(
        icon: Icons.tune,
        title: 'Nota final',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              scale == null
                  ? 'La clase no tiene pesos de evaluación, así que la nota final no se calcula.'
                  : 'Los pesos de la clase suman ${compactNumber(report.totalWeight)}%; '
                        'la nota final se calcula cuando sumen 100%.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Configurar pesos',
              icon: Icons.tune,
              onPressed: () => context.push(
                RoutePaths.gradingSettingsForClass(report.teachingPeriodId),
              ),
            ),
          ],
        ),
      );
    }

    Widget fact(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall?.copyWith(fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    return DesktopSectionCard(
      icon: Icons.emoji_events_outlined,
      title: 'Nota final',
      child: Column(
        children: [
          const SizedBox(height: 16),
          GradeRing(
            value: grade == null ? '—' : grade.toStringAsFixed(2),
            maximum: scale!.maximumValue.toStringAsFixed(2),
            fraction: grade == null ? null : scaleFraction(grade, scale),
            size: 128,
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.outline),
          const SizedBox(height: 12),
          Row(
            children: [
              fact(
                'Puntaje',
                report.score == null
                    ? '—'
                    : '${compactNumber(report.score!)} / 100',
              ),
              fact('Ponderación', '${compactNumber(report.totalWeight)}%'),
              fact(
                'Nota mínima',
                report.passingGrade == null
                    ? '—'
                    : compactNumber(report.passingGrade!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComponentsCard extends StatelessWidget {
  const _ComponentsCard({required this.report});

  final StudentGradeReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scale = report.scale!;
    return DesktopSectionCard(
      icon: Icons.donut_small_outlined,
      title: 'Por componente',
      child: Column(
        children: [
          const SizedBox(height: 8),
          for (final c in report.categories)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        categoryVisuals(c.categoryName).icon,
                        size: 16,
                        color: categoryVisuals(c.categoryName).color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${categoryLabel(c.categoryName)}  ·  ${compactNumber(c.weight)}%',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        c.gradeOnScale == null
                            ? '—'
                            : c.gradeOnScale!.toStringAsFixed(2),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: c.gradeOnScale == null
                          ? 0
                          : scaleFraction(c.gradeOnScale!, scale),
                      minHeight: 6,
                      color: categoryVisuals(c.categoryName).color,
                      backgroundColor: categoryVisuals(
                        c.categoryName,
                      ).color.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The observation, edited in place (no dialog on desktop).
class _ObservationCard extends StatefulWidget {
  const _ObservationCard({super.key, required this.report});

  final StudentGradeReport report;

  @override
  State<_ObservationCard> createState() => _ObservationCardState();
}

class _ObservationCardState extends State<_ObservationCard> {
  late final _text = TextEditingController(
    text: widget.report.observation?.text ?? '',
  );
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await context.read<GradebookProvider>().saveObservation(
      widget.report.teachingPeriodId,
      widget.report.student.id,
      _text.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showApiError(error);
    } else {
      setState(() => _editing = false);
      context.showSuccess('Observación guardada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final observation = widget.report.observation;

    return DesktopSectionCard(
      icon: Icons.chat_bubble_outline,
      title: 'Observaciones',
      linkLabel: _editing ? null : (observation == null ? 'Agregar' : 'Editar'),
      onLink: _editing ? null : () => setState(() => _editing = true),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _editing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _text,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 8,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText:
                          'Cómo va el estudiante en esta clase (solo la ves tú).',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _text.text = observation?.text ?? '';
                                _editing = false;
                              }),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        label: 'Guardar',
                        isLoading: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    observation?.text ??
                        'Sin observaciones sobre este estudiante en la clase.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: observation == null
                          ? AppColors.textSecondary
                          : null,
                    ),
                  ),
                  if (observation?.updatedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Actualizada el ${Formatters.date(observation!.updatedAt!)}',
                      style: textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
