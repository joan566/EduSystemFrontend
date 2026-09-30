import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../domain/entities/exam_entity.dart';
import '../../../domain/entities/submission_entity.dart';
import '../../shared/exam_actions.dart';
import '../../providers/submissions_provider.dart';
import '../../shared/exam_results.dart';
import '../../shared/exam_results_summary.dart';

/// "Resultados": class stats, the two grading entry points, then one row
/// per graded sheet. Loads the whole class at once (the API's max page).
class ExamResultsMobileTab extends StatelessWidget {
  const ExamResultsMobileTab({
    super.key,
    required this.exam,
    required this.period,
  });

  final ExamEntity exam;

  /// The exam's class; null until the classes have loaded.
  final TeachingPeriodEntity? period;

  @override
  Widget build(BuildContext context) {
    final actions = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Calificar PDF',
              icon: Icons.picture_as_pdf_outlined,
              onPressed: exam.ready
                  ? () => ExamActions.openBatches(context, exam.id)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              label: 'Escanear hojas',
              icon: Icons.document_scanner_outlined,
              variant: AppButtonVariant.outlined,
              onPressed: exam.ready
                  ? () => ExamActions.openScanning(context, exam.id)
                  : null,
            ),
          ),
        ],
      ),
    );

    // Stats and actions stay visible while the list loads or is empty, so
    // grading can start from here.
    final state = context.watch<SubmissionsProvider>().results(exam.id);
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _StatsCard(exam: exam, period: period, state: state),
        ),
        actions,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            'Resultados por estudiante',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ExamResultsStateView(
            exam: exam,
            builder: (context, state) => _ResultsCard(exam: exam, state: state),
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.exam,
    required this.period,
    required this.state,
  });

  final ExamEntity exam;
  final TeachingPeriodEntity? period;
  final ListViewState<SubmissionSummaryEntity> state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = ExamResultsSummary.from(state.items, exam);
    final average = summary.average;
    final processed = summary.processed;
    final max = exam.maximumScore;
    final students = period?.studentCount;
    final divider = VerticalDivider(
      width: 1,
      thickness: 1,
      color: colors.outline,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _Stat(
              icon: Icons.people_alt_outlined,
              color: AppColors.accentBlue,
              value: students?.toString() ?? '—',
              label: 'Estudiantes',
            ),
            divider,
            _Stat(
              icon: Icons.description_outlined,
              color: AppColors.accentBlue,
              value: '${exam.numberOfQuestions}',
              label: 'Preguntas',
            ),
            divider,
            _Stat(
              icon: Icons.star_rounded,
              color: AppColors.accentBlue,
              value: average == null
                  ? '—'
                  : max == null
                  ? average.toStringAsFixed(1)
                  : Formatters.grade(average, max, decimals: 1),
              label: 'Promedio',
            ),
            divider,
            _Stat(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              value: '$processed/${students ?? state.totalElements}',
              label: 'Procesados',
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row per graded sheet in a compact table-like card.
class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.exam, required this.state});

  final ExamEntity exam;
  final ListViewState<SubmissionSummaryEntity> state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final header = textTheme.bodySmall?.copyWith(
      fontSize: 11,
      color: AppColors.textSecondary,
    );
    final items = [...state.items]
      ..sort((a, b) => a.studentName.compareTo(b.studentName));

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
            padding: const EdgeInsets.fromLTRB(12, 10, 32, 10),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text('Estudiante', style: header)),
                Expanded(flex: 3, child: Text('Puntaje', style: header)),
                Expanded(flex: 5, child: Text('Estado', style: header)),
              ],
            ),
          ),
          for (final item in items) ...[
            Divider(height: 1, color: colors.outline),
            _ResultRow(exam: exam, item: item),
          ],
          if (state.totalPages > 1) ...[
            Divider(height: 1, color: colors.outline),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Mostrando ${items.length} de ${state.totalElements} hojas.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.exam, required this.item});

  final ExamEntity exam;
  final SubmissionSummaryEntity item;

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final grade = item.finalGrade;
    final max = exam.maximumScore;
    final progress = grade != null && max != null && max > 0
        ? (grade / max).clamp(0.0, 1.0)
        : null;

    return InkWell(
      onTap: () => context.push(RoutePaths.submissionDetail(exam.id, item.id)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.accentBlue.withValues(
                      alpha: 0.12,
                    ),
                    child: Text(
                      _initials(item.studentName),
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.studentName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    grade == null
                        ? '—'
                        : max == null
                        ? grade.toStringAsFixed(1)
                        : Formatters.grade(grade, max, decimals: 1),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: submissionStatusChip(item.status),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              color: AppColors.accentBlue,
                              backgroundColor: colors.outline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Formatters.percentage(progress * 100),
                          style: textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
