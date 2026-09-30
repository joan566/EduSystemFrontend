import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/cached_value.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/desktop/desktop_catalog_header.dart';
import '../../../../core/widgets/desktop/desktop_catalog_relations.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_list_table.dart';
import '../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/academic_period_entity.dart';
import '../providers/academic_periods_provider.dart';
import '../shared/academic_period_actions.dart';
import '../shared/academic_period_form.dart';
import '../shared/period_timeline.dart';
import 'widgets/period_timeline_card.dart';

/// Desktop "Periodos académicos": the periods on a timeline with today
/// marked, a status filter and the table (dates, length, progress, your
/// classes); the running period and how the catalogs relate at the side.
class AcademicPeriodsDesktopView extends StatelessWidget {
  const AcademicPeriodsDesktopView({
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

  static const _sideWidth = 320.0;
  static const _sideBesideMinWidth = 1080.0;

  Future<void> _openForm(
    BuildContext context, {
    AcademicPeriodEntity? initial,
  }) async {
    final data = await showDesktopDialog<AcademicPeriodFormResult>(
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
    final textTheme = Theme.of(context).textTheme;
    final visible = localPage(
      sortPeriods(
        state.items.where((p) => matchesPeriodFilter(p, filter)).toList(),
      ),
      page: page,
    );

    final Widget main = switch (state.status) {
      ViewStatus.initial || ViewStatus.loading => const DesktopListTableSkeleton(
        columns: [
          SkeletonColumn('Periodo', flex: 3, cell: SkeletonCell.badge),
          SkeletonColumn('Fechas', flex: 3),
          SkeletonColumn('Duración', flex: 2),
          SkeletonColumn('Estado', flex: 3, cell: SkeletonCell.chip),
          SkeletonColumn(
            'Tus clases',
            width: 100,
            cell: SkeletonCell.value,
            alignEnd: true,
          ),
        ],
      ),
      ViewStatus.error => AppErrorState(
        exception: state.error!,
        onRetry: () => context.read<AcademicPeriodsProvider>().refresh(),
      ),
      ViewStatus.empty => AppEmptyState(
        title: 'No hay periodos académicos',
        message:
            'Define los cortes del año (por ejemplo 2026-1 y 2026-2) para crear clases.',
        icon: Icons.calendar_month_outlined,
        actionLabel: 'Nuevo periodo',
        onAction: () => _openForm(context),
      ),
      ViewStatus.success => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          PeriodTimelineCard(periods: state.items),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<PeriodStatusFilter>(
              showSelectedIcon: false,
              segments: [
                for (final f in PeriodStatusFilter.values)
                  ButtonSegment(value: f, label: Text(periodFilterLabel(f))),
              ],
              selected: {filter},
              onSelectionChanged: (v) => onFilterChanged(v.first),
            ),
          ),
          const SizedBox(height: 14),
          DesktopListTable<AcademicPeriodEntity>(
            shrinkWrap: true,
            items: visible.items,
            onRowTap: (p) => _openForm(context, initial: p),
            actions: [
              DesktopRowAction(
                icon: Icons.edit_outlined,
                label: 'Editar periodo',
                onTap: (p) => _openForm(context, initial: p),
              ),
              DesktopRowAction(
                icon: Icons.delete_outline,
                label: 'Eliminar periodo',
                destructive: true,
                onTap: (p) => AcademicPeriodActions.delete(context, p),
              ),
            ],
            columns: [
              DesktopListColumn(
                label: 'Periodo',
                flex: 3,
                cell: (p) => Text(
                  p.name,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DesktopListColumn(
                label: 'Fechas',
                flex: 3,
                cell: (p) => Text(periodRange(p), style: textTheme.bodyMedium),
              ),
              DesktopListColumn(
                label: 'Duración',
                flex: 2,
                cell: (p) => Text(
                  '${periodWeeks(p)} semanas',
                  style: textTheme.bodyMedium,
                ),
              ),
              DesktopListColumn(
                label: 'Estado',
                flex: 3,
                cell: (p) {
                  final label = periodStatusLabel(periodStatus(p));
                  final week = currentWeek(p);
                  return Row(
                    children: [
                      AppStatusChip(label: label.label, kind: label.kind),
                      if (week != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Tooltip(
                            message: 'Semana $week de ${periodWeeks(p)}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: periodProgress(p),
                                minHeight: 6,
                                color: AppColors.success,
                                backgroundColor: AppColors.success.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ],
                  );
                },
              ),
              DesktopListColumn(
                label: 'Tus clases',
                width: 100,
                alignEnd: true,
                cell: (p) =>
                    Text('${classes[p.id] ?? 0}', style: textTheme.bodyMedium),
              ),
            ],
            footer: visible.totalPages > 1
                ? AppPagination(
                    page: visible.page,
                    totalPages: visible.totalPages,
                    totalElements: visible.totalElements,
                    onPageChanged: onPageChanged,
                  )
                : null,
          ),
        ],
      ),
    };

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopCatalogHeader(
              title: 'Periodos académicos',
              subtitle:
                  'Los cortes del año lectivo; cada clase pertenece a uno.',
              actions: [
                AppButton(
                  label: 'Nuevo periodo',
                  icon: Icons.add,
                  onPressed: () => _openForm(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < _sideBesideMinWidth) return main;
                  final active = state.items
                      .where((p) => periodStatus(p) == PeriodStatus.active)
                      .firstOrNull;
                  final next = sortPeriods(
                    state.items
                        .where((p) => periodStatus(p) == PeriodStatus.upcoming)
                        .toList(),
                  ).firstOrNull;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: main),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: _sideWidth,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _NowCard(
                                active: active,
                                next: next,
                                classes: classes,
                              ),
                              const SizedBox(height: 16),
                              const DesktopCatalogRelations(
                                current: CatalogKind.periods,
                              ),
                            ],
                          ),
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
}

/// The running period (week, progress, days left) or the next one.
class _NowCard extends StatelessWidget {
  const _NowCard({
    required this.active,
    required this.next,
    required this.classes,
  });

  final AcademicPeriodEntity? active;
  final AcademicPeriodEntity? next;
  final Map<int, int> classes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = this.active;
    final next = this.next;

    if (active == null) {
      return DesktopSectionCard(
        icon: Icons.event_outlined,
        title: 'Ahora',
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            next == null
                ? 'No hay un periodo en curso ni próximo.'
                : 'Ningún periodo en curso. El próximo, ${next.name}, empieza el ${periodRange(next).split(' – ').first}.',
            style: textTheme.bodySmall,
          ),
        ),
      );
    }

    final progress = periodProgress(active);
    final daysLeft =
        DateTime(active.endDate.year, active.endDate.month, active.endDate.day)
            .difference(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            )
            .inDays;
    return DesktopSectionCard(
      icon: Icons.play_circle_outline,
      title: 'En curso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          Text(
            active.name,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(periodRange(active), style: textTheme.bodySmall),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: AppColors.success,
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Semana ${currentWeek(active)} de ${periodWeeks(active)}',
                style: textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            [
              daysLeft == 0 ? 'Termina hoy' : 'Quedan $daysLeft días',
              '${classes[active.id] ?? 0} clases tuyas',
            ].join('  ·  '),
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
