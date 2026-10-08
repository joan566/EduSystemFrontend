import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/cached_value.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mobile/mobile_brand_bar.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/mobile/class_picker_sheet.dart';
import '../../../teaching/presentation/shared/class_picker.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';
import '../shared/exam_actions.dart';
import '../shared/exam_list_filters.dart';
import 'widgets/exam_list_card.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

/// Mobile "Exámenes": brand bar, title, class picker, search + order,
/// status pills, then one card per exam and a "Crear examen" button.
class ExamsMobileView extends StatelessWidget {
  const ExamsMobileView({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    required this.filters,
    required this.onFiltersChanged,
    required this.page,
    required this.onPageChanged,
  });

  final TeachingPeriodEntity? period;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;
  final ExamListFilters filters;
  final ValueChanged<ExamListFilters> onFiltersChanged;

  /// Page of the filtered exams (owned by the page entry point).
  final int page;
  final ValueChanged<int> onPageChanged;

  Future<void> _openSort(BuildContext context) async {
    final picked = await showMobileSheet<ExamSort>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Ordenar exámenes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final sort in ExamSort.values)
              ListTile(
                title: Text(examSortLabel(sort)),
                trailing: filters.sort == sort
                    ? const Icon(Icons.check, color: AppColors.accentBlue)
                    : null,
                onTap: () => Navigator.of(context).pop(sort),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onFiltersChanged(filters.copyWith(sort: picked));
  }

  @override
  Widget build(BuildContext context) {
    final period = this.period;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: period == null
          ? null
          : SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,

              // Espaciado y animaciones
              spacing: 10,
              spaceBetweenChildren: 6,
              renderOverlay: true,
              overlayColor: Colors.black,
              overlayOpacity: 0.4,

              children: [
                // 1. Primera opción: Crear examen
                SpeedDialChild(
                  child: const Icon(Icons.add_task),
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  label: 'Crear examen',
                  labelStyle: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                  onTap: () =>
                      ExamActions.create(context, teachingPeriodId: period.id),
                ),

                SpeedDialChild(
                  child: const Icon(Icons.description_outlined),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.accentBlue,
                  label: 'Importar o exportar plantilla',
                  labelStyle: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                  onTap: () => ExamActions.importFromWord(
                    context,
                    teachingPeriodId: period.id,
                  ),
                ),
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MobileBrandBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Exámenes',
              style: textTheme.headlineLarge?.copyWith(fontSize: 26),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _ClassPicker(value: period, onChanged: onPeriodChanged),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchField(
                    hint: 'Buscar examen...',
                    initialValue: filters.search,
                    onChanged: (search) =>
                        onFiltersChanged(filters.copyWith(search: search)),
                  ),
                ),
                const SizedBox(width: 10),
                _SortButton(
                  active: filters.sort != ExamSort.newest,
                  onPressed: () => _openSort(context),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              children: [
                for (final (status, label) in const [
                  (ExamStatusFilter.all, 'Todos'),
                  (ExamStatusFilter.incomplete, 'Incompletos'),
                  (ExamStatusFilter.ready, 'Listos'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterPill(
                      label: label,
                      selected: filters.status == status,
                      onTap: () =>
                          onFiltersChanged(filters.copyWith(status: status)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: period == null
                ? const SizedBox.shrink()
                : _ExamList(
                    period: period,
                    filters: filters,
                    page: page,
                    onPageChanged: onPageChanged,
                  ),
          ),
        ],
      ),
    );
  }
}

/// One-line class picker: "Castellano — 5° A" with a chevron; the sheet
/// lists every class with its academic period.
class _ClassPicker extends StatelessWidget {
  const _ClassPicker({required this.value, required this.onChanged});

  final TeachingPeriodEntity? value;
  final ValueChanged<TeachingPeriodEntity?> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showMobileClassPicker(context, selected: value);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final teaching = context.watch<TeachingProvider>();
    final all = teaching.allPeriods;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final value = this.value;

    if (all.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.groups_outlined, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Todavía no tienes clases.',
                style: textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => context.push(RoutePaths.teaching),
              child: const Text('Crear una clase'),
            ),
          ],
        ),
      );
    }

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              const Icon(Icons.class_outlined, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value == null
                      ? 'Selecciona una clase'
                      : classPickerLabel(context, value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: active,
      smallSize: 8,
      backgroundColor: AppColors.accentBlue,
      child: IconButton.outlined(
        tooltip: 'Ordenar',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.tune),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? AppColors.accentBlue : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? AppColors.accentBlue : colors.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? Colors.white : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamList extends StatelessWidget {
  const _ExamList({
    required this.period,
    required this.filters,
    required this.page,
    required this.onPageChanged,
  });

  final TeachingPeriodEntity period;
  final ExamListFilters filters;
  final int page;
  final ValueChanged<int> onPageChanged;

  Future<void> _openActions(
    BuildContext context,
    ExamSummaryEntity exam,
  ) async {
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Abrir examen'),
              onTap: () => Navigator.of(context).pop(0),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Descargar hojas de respuesta'),
              subtitle: exam.ready
                  ? null
                  : const Text('Completa las preguntas primero'),
              enabled: exam.ready,
              onTap: () => Navigator.of(context).pop(1),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Eliminar examen'),
              onTap: () => Navigator.of(context).pop(2),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 0:
        context.push(RoutePaths.examDetail(exam.id));
      case 1:
        await ExamActions.downloadAnswerSheets(context, exam.id);
      case 2:
        await ExamActions.delete(context, exam.id, popOnSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExamsProvider>().exams(period.id);

    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const MobileListSkeleton(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 96),
          leading: SkeletonLeading.square,
          trailingWidth: 72,
          meta: true,
        );
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<ExamsProvider>().refreshExams(period.id),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay exámenes en esta clase',
          message: 'Crea un examen para empezar a evaluar a tus estudiantes.',
          icon: Icons.fact_check_outlined,
          actionLabel: 'Crear examen',
          onAction: () =>
              ExamActions.create(context, teachingPeriodId: period.id),
        );
      case ViewStatus.success:
        // The class's whole exam list, filtered and paged in memory.
        final visible = localPage(filters.apply(state.items), page: page);
        final exams = visible.items;
        return ListView(
          // Bottom padding keeps the last card clear of the FAB.
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
          children: [
            if (exams.isEmpty)
              const AppEmptyState(
                title: 'Sin resultados',
                message: 'Ningún examen coincide con la búsqueda o el filtro.',
                icon: Icons.search_off,
              ),
            for (final exam in exams)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExamListCard(
                  exam: exam,
                  students: period.studentCount,
                  onTap: () => context.push(RoutePaths.examDetail(exam.id)),
                  onMore: () => _openActions(context, exam),
                ),
              ),
            if (visible.totalPages > 1)
              AppPagination(
                page: visible.page,
                totalPages: visible.totalPages,
                totalElements: visible.totalElements,
                onPageChanged: onPageChanged,
              ),
          ],
        );
    }
  }
}
