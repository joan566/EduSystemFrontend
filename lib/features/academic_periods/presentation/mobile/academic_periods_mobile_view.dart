import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/cached_value.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mobile/mobile_catalog_card.dart';
import '../../../../core/widgets/mobile/mobile_catalog_header.dart';
import '../../../../core/widgets/mobile/mobile_filter_pills.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/academic_period_entity.dart';
import '../providers/academic_periods_provider.dart';
import '../shared/academic_period_actions.dart';
import '../shared/academic_period_form.dart';
import '../shared/period_timeline.dart';

/// Mobile "Periodos académicos": status pills, then the periods (running
/// first) as cards with a date block, status and, while running, the week
/// and how far along it is.
class AcademicPeriodsMobileView extends StatelessWidget {
  const AcademicPeriodsMobileView({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.page,
    required this.onPageChanged,
  });

  final PeriodStatusFilter filter;
  final ValueChanged<PeriodStatusFilter> onFilterChanged;

  /// Page of the filtered periods (owned by the page entry point).
  final int page;
  final ValueChanged<int> onPageChanged;

  Future<void> _openForm(
    BuildContext context, {
    AcademicPeriodEntity? initial,
  }) async {
    final data = await showMobileForm<AcademicPeriodFormResult>(
      context,
      child: AcademicPeriodForm(initial: initial),
    );
    if (data == null || !context.mounted) return;
    await AcademicPeriodActions.save(context, initial: initial, data: data);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AcademicPeriodsProvider>().state;
    final classes = classesByPeriod(
      context.watch<TeachingProvider>().allPeriods,
    );
    final active = state.items
        .where((p) => periodStatus(p) == PeriodStatus.active)
        .firstOrNull;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileCatalogHeader(
            title: 'Periodos académicos',
            subtitle: active == null
                ? 'Los cortes del año lectivo'
                : 'En curso: ${active.name} · semana ${currentWeek(active)} de ${periodWeeks(active)}',
            addTooltip: 'Nuevo periodo',
            onAdd: () => _openForm(context),
          ),
          const SizedBox(height: 14),
          MobileFilterPills<PeriodStatusFilter>(
            options: PeriodStatusFilter.values,
            selected: filter,
            label: periodFilterLabel,
            onSelected: onFilterChanged,
          ),
          Expanded(
            child: switch (state.status) {
              ViewStatus.initial || ViewStatus.loading => const AppLoading(),
              ViewStatus.error => AppErrorState(
                exception: state.error!,
                onRetry: () =>
                    context.read<AcademicPeriodsProvider>().refresh(),
              ),
              ViewStatus.empty => AppEmptyState(
                title: 'No hay periodos académicos',
                message:
                    'Define los cortes del año (por ejemplo 2026-1 y 2026-2) para crear clases.',
                icon: Icons.calendar_month_outlined,
                actionLabel: 'Nuevo periodo',
                onAction: () => _openForm(context),
              ),
              ViewStatus.success => () {
                final visible = localPage(
                  sortPeriods(
                    state.items
                        .where((p) => matchesPeriodFilter(p, filter))
                        .toList(),
                  ),
                  page: page,
                );
                final periods = visible.items;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (periods.isEmpty)
                      AppEmptyState(
                        title:
                            'Sin periodos ${periodFilterLabel(filter).toLowerCase()}',
                        icon: Icons.event_busy_outlined,
                      ),
                    for (final p in periods)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PeriodCard(
                          period: p,
                          classes: classes[p.id] ?? 0,
                          onEdit: () => _openForm(context, initial: p),
                          onDelete: () =>
                              AcademicPeriodActions.delete(context, p),
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
              }(),
            },
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.period,
    required this.classes,
    required this.onEdit,
    required this.onDelete,
  });

  final AcademicPeriodEntity period;
  final int classes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = periodStatus(period);
    final label = periodStatusLabel(status);
    final textTheme = Theme.of(context).textTheme;
    final color = switch (status) {
      PeriodStatus.active => AppColors.success,
      PeriodStatus.upcoming => AppColors.accentBlue,
      PeriodStatus.finished => AppColors.textSecondary,
    };
    final week = currentWeek(period);

    return MobileCatalogCard(
      leading: _DateBlock(date: period.startDate, color: color),
      title: period.name,
      subtitle: periodRange(period),
      meta: Text(
        '${periodWeeks(period)} semanas  ·  '
        '${classes == 0
            ? 'sin clases tuyas'
            : classes == 1
            ? '1 clase tuya'
            : '$classes clases tuyas'}',
      ),
      trailing: FittedBox(
        child: AppStatusChip(label: label.label, kind: label.kind),
      ),
      editLabel: 'Editar periodo',
      deleteLabel: 'Eliminar periodo',
      onEdit: onEdit,
      onDelete: onDelete,
      footer: week == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: periodProgress(period),
                    minHeight: 6,
                    color: AppColors.success,
                    backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Semana $week de ${periodWeeks(period)}  ·  ${(periodProgress(period) * 100).round()}% transcurrido',
                  style: textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
    );
  }
}

/// The start date as a calendar block: month over day.
class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date, required this.color});

  final DateTime date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            monthShort(date),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
