import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/shared/teaching_period_selector.dart';
import '../../domain/entities/activity_entity.dart';
import '../providers/activities_provider.dart';
import '../shared/activity_actions.dart';
import '../shared/activity_form.dart';

class ActivitiesMobileView extends StatelessWidget {
  const ActivitiesMobileView({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    required this.page,
    required this.onPageChanged,
    this.preferredPeriodId,
  });

  final TeachingPeriodEntity? period;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;

  /// Page of the class's activities (owned by the page entry point).
  final int page;
  final ValueChanged<int> onPageChanged;

  /// Class the selector picks on first load, if present.
  final int? preferredPeriodId;

  Future<void> _create(BuildContext context) async {
    final period = this.period;
    if (period == null) return;
    final data = await showMobileForm<ActivityFormResult>(
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
      floatingActionButton: period == null
          ? null
          : FloatingActionButton(
              onPressed: () => _create(context),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          const MobilePageHeader(title: 'Actividades'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TeachingPeriodSelector(
              preferredId: preferredPeriodId,
              value: period,
              onChanged: onPeriodChanged,
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
        return const MobileListSkeleton(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 88),
          leading: SkeletonLeading.square,
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
        return MobileCardList<ActivityEntity>(
          items: state.items,
          footer: AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: onPageChanged,
          ),
          itemBuilder: (context, item) => AppListTile(
            icon: Icons.assignment_outlined,
            title: item.name,
            subtitle: item.activityType ?? 'Actividad',
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push(RoutePaths.activityDetail(item.id)),
          ),
        );
    }
  }
}
