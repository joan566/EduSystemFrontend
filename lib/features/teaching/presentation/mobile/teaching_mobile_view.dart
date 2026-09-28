import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';
import '../shared/assignment_filters_bar.dart';
import '../shared/teaching_actions.dart';
import '../shared/teaching_forms.dart';
import '../shared/teaching_widgets.dart';

/// Mobile: compact header with the counts, tabs, card lists and a FAB that
/// creates whatever the current tab lists.
class TeachingMobileView extends StatelessWidget {
  const TeachingMobileView({
    super.key,
    required this.tabController,
    required this.filters,
    required this.onFiltersChanged,
  });

  final TabController tabController;
  final AssignmentFilters filters;
  final ValueChanged<AssignmentFilters> onFiltersChanged;

  Future<void> _createAssignment(BuildContext context) async {
    final inputs = TeachingActions.assignmentFormInputs(context);
    if (inputs == null) return;
    final data = await showMobileForm<AssignmentFormResult>(
      context,
      child: AssignmentForm(subjects: inputs.subjects, courses: inputs.courses),
    );
    if (data == null || !context.mounted) return;
    await TeachingActions.createAssignment(context, data);
  }

  Future<void> _createPeriod(BuildContext context) async {
    final inputs = TeachingActions.periodFormInputs(context);
    if (inputs == null) return;
    final data = await showMobileForm<TeachingPeriodFormResult>(
      context,
      child: TeachingPeriodForm(
        assignments: inputs.assignments,
        periods: inputs.periods,
      ),
    );
    if (data == null || !context.mounted) return;
    await TeachingActions.createPeriod(context, data);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeachingProvider>();
    final onAssignmentsTab = tabController.index == 0;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => onAssignmentsTab
            ? _createAssignment(context)
            : _createPeriod(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          MobilePageHeader(
            title: 'Clases',
            subtitle:
                '${provider.assignmentsState.totalElements} asignaciones · '
                '${provider.periodsState.totalElements} clases por periodo',
          ),
          TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: 'Asignaciones'),
              Tab(text: 'Por periodo'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _AssignmentsTab(
                  filters: filters,
                  onFiltersChanged: onFiltersChanged,
                  onCreate: () => _createAssignment(context),
                ),
                _PeriodsTab(onCreate: () => _createPeriod(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({
    required this.filters,
    required this.onFiltersChanged,
    required this.onCreate,
  });

  final AssignmentFilters filters;
  final ValueChanged<AssignmentFilters> onFiltersChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().assignmentsState;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AssignmentFiltersBar(
            filters: filters,
            onChanged: onFiltersChanged,
          ),
        ),
        Expanded(child: _buildList(context, state)),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    ListViewState<TeachingAssignmentEntity> state,
  ) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<TeachingProvider>().loadAssignments(),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No tienes asignaciones',
          message:
              'Asigna una materia a un curso para empezar a dictar clases.',
          icon: Icons.groups_outlined,
          actionLabel: 'Nueva asignación',
          onAction: onCreate,
        );
      case ViewStatus.success:
        return MobileCardList<TeachingAssignmentEntity>(
          items: state.items,
          footer: AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) =>
                context.read<TeachingProvider>().loadAssignments(
                  page: page,
                  subjectId: filters.subjectId,
                  active: filters.active,
                ),
          ),
          itemBuilder: (context, item) => AppListTile(
            icon: Icons.groups_outlined,
            iconColor: subjectColor(item.subjectId),
            title: item.displayName,
            subtitle: 'Año académico ${item.academicYear}',
            trailing: AssignmentActions(item: item),
          ),
        );
    }
  }
}

class _PeriodsTab extends StatelessWidget {
  const _PeriodsTab({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().periodsState;

    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<TeachingProvider>().loadPeriods(),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No tienes clases por periodo',
          message:
              'Vincula una asignación con un periodo académico para empezar.',
          icon: Icons.calendar_month_outlined,
          actionLabel: 'Nueva clase',
          onAction: onCreate,
        );
      case ViewStatus.success:
        return MobileCardList<TeachingPeriodEntity>(
          items: state.items,
          footer: AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) =>
                context.read<TeachingProvider>().loadPeriods(page: page),
          ),
          itemBuilder: (context, item) => AppListTile(
            icon: Icons.calendar_month_outlined,
            iconColor: subjectColor(item.subjectId),
            title: item.displayName,
            subtitleMaxLines: 2,
            subtitle:
                '${Formatters.date(item.startDate)} — ${Formatters.date(item.endDate)}',
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => TeachingActions.deletePeriod(context, item),
            ),
            onTap: () => context.push(RoutePaths.teachingPeriodDetail(item.id)),
          ),
        );
    }
  }
}
