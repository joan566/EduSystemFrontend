import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/desktop/class_picker_field.dart';
import '../../domain/entities/activity_entity.dart';
import '../providers/activities_provider.dart';
import '../shared/activity_actions.dart';
import '../shared/activity_form.dart';

class ActivitiesDesktopView extends StatelessWidget {
  const ActivitiesDesktopView({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    required this.page,
    required this.onPageChanged,
  });

  final TeachingPeriodEntity? period;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;

  /// Page of the class's activities (owned by the page entry point).
  final int page;
  final ValueChanged<int> onPageChanged;

  Future<void> _create(BuildContext context) async {
    final period = this.period;
    if (period == null) return;
    final data = await showDesktopDialog<ActivityFormResult>(
      context,
      child: const ActivityForm(),
    );
    if (data == null || !context.mounted) return;
    await ActivityActions.create(
      context,
      teachingPeriodId: period.id,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final period = this.period;
    final state = period == null
        ? const ListViewState<ActivityEntity>()
        : context.watch<ActivitiesProvider>().activitiesPage(
            period.id,
            page: page,
          );

    return Scaffold(
      body: Column(
        children: [
          DesktopPageHeader(
            title: 'Actividades',
            subtitle: 'Talleres, proyectos y demás actividades evaluables.',
            actions: [
              if (period != null)
                AppButton(
                  label: 'Nueva actividad',
                  icon: Icons.add,
                  onPressed: () => _create(context),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DesktopClassPickerField(
                value: period,
                onChanged: onPeriodChanged,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: period == null
                ? const AppEmptyState(
                    title: 'Selecciona una clase',
                    message: 'Elige una clase arriba para ver sus actividades.',
                    icon: Icons.assignment_outlined,
                  )
                : _buildBody(context, state, period),
          ),
          if (period != null && state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: onPageChanged,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ListViewState<ActivityEntity> state,
    TeachingPeriodEntity period,
  ) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const DesktopDataTableSkeleton(
          columns: [
            SkeletonColumn('Nombre', flex: 3),
            SkeletonColumn('Tipo', flex: 2),
            SkeletonColumn('Puntaje máx.', cell: SkeletonCell.value),
            SkeletonColumn('Fecha', flex: 2),
          ],
        );
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<ActivitiesProvider>().refreshActivities(period.id),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay actividades en esta clase',
          message:
              'Crea una actividad para empezar a registrar calificaciones.',
          icon: Icons.assignment_outlined,
          actionLabel: 'Nueva actividad',
          onAction: () => _create(context),
        );
      case ViewStatus.success:
        return DesktopDataTable<ActivityEntity>(
          items: state.items,
          onRowTap: (item) => context.push(RoutePaths.activityDetail(item.id)),
          columns: [
            DesktopDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.name),
            ),
            DesktopDataColumn(
              label: 'Tipo',
              cellBuilder: (item) => Text(item.activityType ?? '—'),
            ),
            DesktopDataColumn(
              label: 'Puntaje máx.',
              cellBuilder: (item) => Text(item.maximumScore.toStringAsFixed(2)),
            ),
            DesktopDataColumn(
              label: 'Fecha',
              cellBuilder: (item) => Text(
                item.evaluationDate == null
                    ? '—'
                    : Formatters.date(item.evaluationDate!),
              ),
            ),
          ],
        );
    }
  }
}
