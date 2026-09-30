import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/cached_value.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';
import '../shared/exam_actions.dart';
import '../shared/exam_list_filters.dart';
import 'widgets/exam_preview_panel.dart';
import 'widgets/exams_table.dart';

/// Desktop "Exámenes": a filter toolbar over one dense table of the class's
/// exams, with the selected exam previewed beside it.
///
/// Unlike mobile (cards + bottom sheets), selection shows where an exam
/// stands (questions, sheets, grading) without leaving the list, and each
/// tab of the exam is one click away. The preview pane only fits from
/// [_previewMinWidth]; below it a click opens the exam.
class ExamsDesktopView extends StatelessWidget {
  const ExamsDesktopView({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    required this.filters,
    required this.onFiltersChanged,
    required this.selectedExamId,
    required this.onSelect,
    required this.page,
    required this.onPageChanged,
  });

  final TeachingPeriodEntity? period;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;
  final ExamListFilters filters;
  final ValueChanged<ExamListFilters> onFiltersChanged;
  final int? selectedExamId;
  final ValueChanged<int?> onSelect;

  /// Page of the filtered exams (owned by the page entry point).
  final int page;
  final ValueChanged<int> onPageChanged;

  static const _previewMinWidth = 1100.0;
  static const _previewWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    final period = this.period;
    // The class's whole exam list, filtered and paged in memory.
    final state = period == null
        ? const ListViewState<ExamSummaryEntity>()
        : context.watch<ExamsProvider>().exams(period.id);
    final teaching = context.watch<TeachingProvider>();
    final classes = teaching.allPeriods;
    final filtered = filters.apply(state.items);
    final visible = localPage(filtered, page: page);
    final exams = visible.items;
    final selected = filtered.where((e) => e.id == selectedExamId).firstOrNull;

    final actions = ExamRowActions(
      onSelect: (exam) => onSelect(exam.id),
      onOpen: (exam, {tab}) =>
          context.push(RoutePaths.examDetail(exam.id, tab: tab)),
      onDownloadSheets: (exam) =>
          ExamActions.downloadAnswerSheets(context, exam.id),
      onDelete: (exam) =>
          ExamActions.delete(context, exam.id, popOnSuccess: false),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              period: period,
              exams: state.items,
              onCreate: period == null
                  ? null
                  : () => ExamActions.create(
                      context,
                      teachingPeriodId: period.id,
                    ),
            ),
            const SizedBox(height: 18),
            _Toolbar(
              classes: classes,
              period: period,
              onPeriodChanged: onPeriodChanged,
              filters: filters,
              onFiltersChanged: onFiltersChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showPreview = constraints.maxWidth >= _previewMinWidth;
                  final table = _body(
                    context,
                    state: state,
                    visible: visible,
                    exams: exams,
                    noClasses: teaching.allPeriodsLoaded && classes.isEmpty,
                    actions: actions,
                    clickOpens: !showPreview,
                  );
                  if (!showPreview || period == null) return table;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: table),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: _previewWidth,
                        child: ExamPreviewPanel(
                          exam: selected,
                          period: period,
                          actions: actions,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required ListViewState<ExamSummaryEntity> state,
    required ListViewState<ExamSummaryEntity> visible,
    required List<ExamSummaryEntity> exams,
    required bool noClasses,
    required ExamRowActions actions,
    required bool clickOpens,
  }) {
    final period = this.period;
    if (period == null) {
      return noClasses
          ? AppEmptyState(
              title: 'Todavía no tienes clases',
              message: 'Crea una clase para empezar a hacer exámenes.',
              icon: Icons.groups_outlined,
              actionLabel: 'Ir a Clases',
              onAction: () => context.go(RoutePaths.teaching),
            )
          : const AppLoading();
    }
    return switch (state.status) {
      ViewStatus.initial || ViewStatus.loading => const AppLoading(),
      ViewStatus.error => AppErrorState(
        exception: state.error!,
        onRetry: () => context.read<ExamsProvider>().refreshExams(period.id),
      ),
      ViewStatus.empty => AppEmptyState(
        title: 'No hay exámenes en esta clase',
        message: 'Crea un examen para empezar a evaluar a tus estudiantes.',
        icon: Icons.fact_check_outlined,
        actionLabel: 'Nuevo examen',
        onAction: () =>
            ExamActions.create(context, teachingPeriodId: period.id),
      ),
      ViewStatus.success when exams.isEmpty => const AppEmptyState(
        title: 'Sin resultados',
        message: 'Ningún examen coincide con la búsqueda o el filtro.',
        icon: Icons.search_off,
      ),
      ViewStatus.success => ExamsTable(
        exams: exams,
        selectedExamId: selectedExamId,
        actions: actions,
        clickOpens: clickOpens,
        footer: visible.totalPages > 1
            ? AppPagination(
                page: visible.page,
                totalPages: visible.totalPages,
                totalElements: visible.totalElements,
                onPageChanged: onPageChanged,
              )
            : null,
      ),
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.period,
    required this.exams,
    required this.onCreate,
  });

  final TeachingPeriodEntity? period;
  final List<ExamSummaryEntity> exams;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final period = this.period;
    final ready = exams.where((e) => e.ready).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Exámenes', style: textTheme.headlineLarge),
              const SizedBox(height: 2),
              Text(
                period == null
                    ? 'Crea, prepara y califica los exámenes de tus clases.'
                    : '${exams.length} exámenes en ${period.subjectName} — '
                          '${period.courseLabel}  ·  $ready listos  ·  '
                          '${exams.length - ready} incompletos',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AppButton(label: 'Nuevo examen', icon: Icons.add, onPressed: onCreate),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.classes,
    required this.period,
    required this.onPeriodChanged,
    required this.filters,
    required this.onFiltersChanged,
  });

  final List<TeachingPeriodEntity> classes;
  final TeachingPeriodEntity? period;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;
  final ExamListFilters filters;
  final ValueChanged<ExamListFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: AppDropdown<TeachingPeriodEntity>(
            label: 'Clase',
            value: classes.where((c) => c.id == period?.id).firstOrNull,
            items: classes,
            itemLabel: (c) => c.displayName,
            onChanged: onPeriodChanged,
          ),
        ),
        SizedBox(
          width: 280,
          child: AppSearchField(
            hint: 'Buscar examen...',
            initialValue: filters.search,
            onChanged: (search) =>
                onFiltersChanged(filters.copyWith(search: search)),
          ),
        ),
        SegmentedButton<ExamStatusFilter>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ExamStatusFilter.all, label: Text('Todos')),
            ButtonSegment(
              value: ExamStatusFilter.incomplete,
              label: Text('Incompletos'),
            ),
            ButtonSegment(value: ExamStatusFilter.ready, label: Text('Listos')),
          ],
          selected: {filters.status},
          onSelectionChanged: (value) =>
              onFiltersChanged(filters.copyWith(status: value.first)),
        ),
        SizedBox(
          width: 220,
          child: AppDropdown<ExamSort>(
            label: 'Ordenar',
            value: filters.sort,
            items: ExamSort.values,
            itemLabel: examSortLabel,
            onChanged: (sort) {
              if (sort != null) onFiltersChanged(filters.copyWith(sort: sort));
            },
          ),
        ),
      ],
    );
  }
}
