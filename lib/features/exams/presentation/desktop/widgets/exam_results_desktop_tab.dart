import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../../core/widgets/desktop/desktop_stat_card.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../../../core/widgets/shared/app_search_field.dart';
import '../../../../students/presentation/providers/students_provider.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../../teaching/presentation/shared/class_lookup.dart';
import '../../../domain/entities/exam_entity.dart';
import '../../../domain/entities/submission_entity.dart';
import '../../providers/submissions_provider.dart';
import '../../shared/exam_actions.dart';
import '../../shared/exam_results.dart';
import '../../shared/exam_results_summary.dart';
import 'grade_distribution_chart.dart';

enum _StatusFilter { all, processed, review, failed }

enum _SortColumn { student, grade, status, date }

/// "Resultados" on desktop: grading actions and filters, a KPI row, the
/// sortable per-student table and, beside it, the grade distribution and
/// the students still without a graded sheet.
class ExamResultsDesktopTab extends StatefulWidget {
  const ExamResultsDesktopTab({
    super.key,
    required this.exam,
    required this.period,
  });

  final ExamEntity exam;

  /// The exam's class; null until the classes have loaded.
  final TeachingPeriodEntity? period;

  @override
  State<ExamResultsDesktopTab> createState() => _ExamResultsDesktopTabState();
}

class _ExamResultsDesktopTabState extends State<ExamResultsDesktopTab> {
  static const _railWidth = 320.0;
  static const _railBesideMinWidth = 1100.0;

  String _search = '';
  _StatusFilter _status = _StatusFilter.all;
  _SortColumn _sort = _SortColumn.student;
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoster());
  }

  @override
  void didUpdateWidget(covariant ExamResultsDesktopTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period?.groupId != widget.period?.groupId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoster());
    }
  }

  void _loadRoster() {
    final period = widget.period;
    if (!mounted || period == null) return;
    final students = context.read<StudentsProvider>();
    students.ensureGroupRoster(period.groupId);
  }

  void _sortBy(_SortColumn column) => setState(() {
    if (_sort == column) {
      _ascending = !_ascending;
    } else {
      _sort = column;
      // Grades read best highest-first; everything else A→Z / oldest first.
      _ascending = column != _SortColumn.grade;
    }
  });

  List<SubmissionSummaryEntity> _visible(List<SubmissionSummaryEntity> all) {
    final rows = all
        .where(
          (s) => switch (_status) {
            _StatusFilter.all => true,
            _StatusFilter.processed => s.status == SubmissionStatus.processed,
            _StatusFilter.review => s.status == SubmissionStatus.reviewRequired,
            _StatusFilter.failed => s.status == SubmissionStatus.failed,
          },
        )
        .where((s) => matchesSearch(_search, [s.studentName, s.studentCode]))
        .toList();
    int compare(SubmissionSummaryEntity a, SubmissionSummaryEntity b) =>
        switch (_sort) {
          _SortColumn.student => a.studentName.compareTo(b.studentName),
          _SortColumn.grade => (a.finalGrade ?? -1).compareTo(
            b.finalGrade ?? -1,
          ),
          _SortColumn.status => a.status.index.compareTo(b.status.index),
          _SortColumn.date =>
            (a.processedAt ?? a.submittedAt ?? DateTime(0)).compareTo(
              b.processedAt ?? b.submittedAt ?? DateTime(0),
            ),
        };
    rows.sort((a, b) => _ascending ? compare(a, b) : compare(b, a));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final state = context.watch<SubmissionsProvider>().results(exam.id);
    final summary = ExamResultsSummary.from(state.items, exam);

    final table = ExamResultsStateView(
      exam: exam,
      builder: (context, state) => _ResultsTable(
        exam: exam,
        rows: _visible(state.items),
        total: state.totalElements,
        sort: _sort,
        ascending: _ascending,
        onSort: _sortBy,
      ),
    );

    final rail = [
      if (summary.bins.isNotEmpty)
        DesktopSectionCard(
          icon: Icons.bar_chart_rounded,
          title: 'Distribución de notas',
          subtitle: '${summary.graded} calificados',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: summary.graded == 0
                ? Text(
                    'Aparecerá cuando haya hojas calificadas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : GradeDistributionChart(bins: summary.bins),
          ),
        ),
      _MissingStudentsCard(
        exam: exam,
        period: widget.period,
        submissions: state.items,
        loaded:
            state.status == ViewStatus.success ||
            state.status == ViewStatus.empty,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final railBeside = constraints.maxWidth >= _railBesideMinWidth;
        return ListView(
          padding: const EdgeInsets.only(top: 20, bottom: 24),
          children: [
            _Toolbar(
              exam: exam,
              status: _status,
              onStatusChanged: (status) => setState(() => _status = status),
              onSearchChanged: (search) => setState(() => _search = search),
            ),
            const SizedBox(height: 16),
            _Kpis(
              exam: exam,
              summary: summary,
              students: widget.period?.studentCount,
              onShowReview: () =>
                  setState(() => _status = _StatusFilter.review),
            ),
            const SizedBox(height: 20),
            if (railBeside)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: table),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: _railWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, card) in rail.indexed) ...[
                          if (i > 0) const SizedBox(height: 20),
                          card,
                        ],
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              table,
              for (final card in rail) ...[const SizedBox(height: 20), card],
            ],
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.exam,
    required this.status,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  final ExamEntity exam;
  final _StatusFilter status;
  final ValueChanged<_StatusFilter> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: AppSearchField(
                  hint: 'Buscar estudiante...',
                  onChanged: onSearchChanged,
                ),
              ),
              SegmentedButton<_StatusFilter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _StatusFilter.all, label: Text('Todas')),
                  ButtonSegment(
                    value: _StatusFilter.processed,
                    label: Text('Procesadas'),
                  ),
                  ButtonSegment(
                    value: _StatusFilter.review,
                    label: Text('Por revisar'),
                  ),
                  ButtonSegment(
                    value: _StatusFilter.failed,
                    label: Text('Con error'),
                  ),
                ],
                selected: {status},
                onSelectionChanged: (value) => onStatusChanged(value.first),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: exam.ready ? '' : 'Completa las preguntas primero',
          child: AppButton(
            label: 'Calificar PDF',
            icon: Icons.picture_as_pdf_outlined,
            variant: AppButtonVariant.outlined,
            onPressed: exam.ready
                ? () => ExamActions.openBatches(context, exam.id)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        AppButton(
          label: 'Escanear hoja',
          icon: Icons.document_scanner_outlined,
          onPressed: exam.ready
              ? () => ExamActions.openScanning(context, exam.id)
              : null,
        ),
      ],
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({
    required this.exam,
    required this.summary,
    required this.students,
    required this.onShowReview,
  });

  final ExamEntity exam;
  final ExamResultsSummary summary;
  final int? students;
  final VoidCallback onShowReview;

  String _grade(double? value) {
    if (value == null) return '—';
    final max = exam.maximumScore;
    return max == null
        ? value.toStringAsFixed(1)
        : Formatters.grade(value, max, decimals: 1);
  }

  @override
  Widget build(BuildContext context) {
    final lowest = summary.lowest, highest = summary.highest;
    final cards = [
      DesktopStatCard(
        label: 'Calificados',
        value: students == null
            ? '${summary.graded}'
            : '${summary.graded} / $students',
        icon: Icons.fact_check_outlined,
        accentColor: AppColors.accentBlue,
      ),
      DesktopStatCard(
        label: 'Promedio',
        value: _grade(summary.average),
        icon: Icons.star_outline_rounded,
        accentColor: AppColors.accentPurple,
      ),
      DesktopStatCard(
        label: 'Nota más baja – más alta',
        value: lowest == null || highest == null
            ? '—'
            : '${lowest.toStringAsFixed(1)} – ${highest.toStringAsFixed(1)}',
        icon: Icons.swap_vert,
        accentColor: AppColors.accentTeal,
      ),
      DesktopStatCard(
        label: 'Por revisar',
        value: '${summary.reviewRequired}',
        icon: Icons.warning_amber_rounded,
        accentColor: AppColors.warning,
        onTap: summary.reviewRequired > 0 ? onShowReview : null,
      ),
    ];
    return Row(
      children: [
        for (final (i, card) in cards.indexed) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: card),
        ],
      ],
    );
  }
}

const _flexStudent = 5;
const _flexGrade = 4;
const _flexStatus = 3;
const _flexDate = 3;

class _ResultsTable extends StatelessWidget {
  const _ResultsTable({
    required this.exam,
    required this.rows,
    required this.total,
    required this.sort,
    required this.ascending,
    required this.onSort,
  });

  final ExamEntity exam;
  final List<SubmissionSummaryEntity> rows;
  final int total;
  final _SortColumn sort;
  final bool ascending;
  final ValueChanged<_SortColumn> onSort;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget header(String label, _SortColumn column, int flex) => Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(column),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                label.toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  letterSpacing: 0.4,
                  color: sort == column ? AppColors.accentBlue : null,
                ),
              ),
              if (sort == column) ...[
                const SizedBox(width: 4),
                Icon(
                  ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: AppColors.accentBlue,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
            padding: const EdgeInsets.fromLTRB(20, 10, 48, 10),
            child: Row(
              children: [
                header('Estudiante', _SortColumn.student, _flexStudent),
                header('Nota', _SortColumn.grade, _flexGrade),
                header('Estado', _SortColumn.status, _flexStatus),
                header('Procesada', _SortColumn.date, _flexDate),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outline),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Ninguna hoja coincide con la búsqueda o el filtro.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ),
          for (final (i, item) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: colors.outline),
            _ResultRow(exam: exam, item: item),
          ],
          Divider(height: 1, color: colors.outline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              rows.length == total
                  ? '$total hojas'
                  : 'Mostrando ${rows.length} de $total hojas',
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatefulWidget {
  const _ResultRow({required this.exam, required this.item});

  final ExamEntity exam;
  final SubmissionSummaryEntity item;

  @override
  State<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends State<_ResultRow> {
  bool _hovering = false;

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final item = widget.item;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final grade = item.finalGrade;
    final max = exam.maximumScore;
    final fraction = grade != null && max != null && max > 0
        ? (grade / max).clamp(0.0, 1.0)
        : null;
    final date = item.processedAt ?? item.submittedAt;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: _hovering
            ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
            : Colors.transparent,
        child: InkWell(
          onTap: () =>
              context.push(RoutePaths.submissionDetail(exam.id, item.id)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  flex: _flexStudent,
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item.studentCode,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: _flexGrade,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          submissionGradeLabel(item, exam),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (fraction != null)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 6,
                                color: AppColors.accentBlue,
                                backgroundColor: AppColors.accentBlue
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: _flexStatus,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Tooltip(
                      message: item.statusDetail ?? '',
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: submissionStatusChip(item.status),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: _flexDate,
                  child: Text(
                    date == null ? '—' : Formatters.dateTime(date),
                    style: textTheme.bodySmall,
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
        ),
      ),
    );
  }
}

/// Students of the class with no sheet yet: who still needs to be scanned.
class _MissingStudentsCard extends StatelessWidget {
  const _MissingStudentsCard({
    required this.exam,
    required this.period,
    required this.submissions,
    required this.loaded,
  });

  final ExamEntity exam;
  final TeachingPeriodEntity? period;
  final List<SubmissionSummaryEntity> submissions;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final period = this.period;
    final roster = period == null
        ? null
        : context.watch<StudentsProvider>().groupRoster(period.groupId);
    final rosterReady = roster != null && roster.status == ViewStatus.success;

    final withSheet = {for (final s in submissions) s.studentId};
    final missing = rosterReady && loaded
        ? (roster.items.where((s) => !withSheet.contains(s.id)).toList()
            ..sort((a, b) => a.lastName.compareTo(b.lastName)))
        : null;

    return DesktopSectionCard(
      icon: Icons.person_search_outlined,
      title: 'Sin hoja',
      subtitle: missing == null ? null : '${missing.length} estudiantes',
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: missing == null
            ? Text(
                roster?.status == ViewStatus.error
                    ? 'No se pudo cargar el curso.'
                    : 'Cargando estudiantes...',
                style: textTheme.bodySmall,
              )
            : missing.isEmpty
            ? Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Todos los estudiantes tienen su hoja.',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, student) in missing.take(12).indexed) ...[
                    if (i > 0) Divider(height: 1, color: colors.outline),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            student.studentCode,
                            style: textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (missing.length > 12)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'y ${missing.length - 12} más',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  if (exam.ready) ...[
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Escanear hoja',
                      icon: Icons.document_scanner_outlined,
                      variant: AppButtonVariant.outlined,
                      expand: true,
                      onPressed: () =>
                          ExamActions.openScanning(context, exam.id),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
