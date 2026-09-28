import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_hero_banner.dart';
import '../../../../core/widgets/desktop/desktop_stat_card.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';
import '../shared/assignment_filters_bar.dart';
import '../shared/teaching_actions.dart';
import '../shared/teaching_forms.dart';
import '../shared/teaching_widgets.dart';

/// Desktop: hero banner with the create action, KPI cards, tabs with data
/// tables.
class TeachingDesktopView extends StatelessWidget {
  const TeachingDesktopView({
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
    final data = await showDesktopDialog<AssignmentFormResult>(
      context,
      child: AssignmentForm(subjects: inputs.subjects, courses: inputs.courses),
    );
    if (data == null || !context.mounted) return;
    await TeachingActions.createAssignment(context, data);
  }

  Future<void> _createPeriod(BuildContext context) async {
    final inputs = TeachingActions.periodFormInputs(context);
    if (inputs == null) return;
    final data = await showDesktopDialog<TeachingPeriodFormResult>(
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
    final assignmentsState = provider.assignmentsState;
    final periodsState = provider.periodsState;
    final onAssignmentsTab = tabController.index == 0;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              children: [
                DesktopHeroBanner(
                  eyebrow: 'Clases',
                  title: 'Gestiona tus clases ',
                  titleHighlight: 'académicas',
                  subtitle:
                      'Aquí puedes ver, crear y administrar las clases que '
                      'impartes.',
                  icon: Icons.groups_outlined,
                  ctaLabel: onAssignmentsTab
                      ? 'Nueva asignación'
                      : 'Nueva clase',
                  ctaIcon: Icons.add,
                  onCtaPressed: () => onAssignmentsTab
                      ? _createAssignment(context)
                      : _createPeriod(context),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DesktopStatCard(
                        label: 'Asignaciones',
                        value: '${assignmentsState.totalElements}',
                        hasError: assignmentsState.status == ViewStatus.error,
                        icon: Icons.groups_outlined,
                        accentColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DesktopStatCard(
                        label: 'Clases por periodo',
                        value: '${periodsState.totalElements}',
                        hasError: periodsState.status == ViewStatus.error,
                        icon: Icons.calendar_month_outlined,
                        accentColor: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: 'Asignaciones'),
              Tab(text: 'Clases por periodo'),
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
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 520,
              child: AssignmentFiltersBar(
                filters: filters,
                onChanged: onFiltersChanged,
              ),
            ),
          ),
        ),
        Expanded(child: _buildList(context, state)),
        if (state.status == ViewStatus.success)
          AppPagination(
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
        return DesktopDataTable<TeachingAssignmentEntity>(
          items: state.items,
          columns: [
            DesktopDataColumn(
              label: 'Clase',
              cellBuilder: (item) => Text(item.displayName),
            ),
            DesktopDataColumn(
              label: 'Materia',
              cellBuilder: (item) => SubjectBadge(
                name: item.subjectName,
                color: subjectColor(item.subjectId),
              ),
            ),
            DesktopDataColumn(
              label: 'Año académico',
              cellBuilder: (item) => Text('${item.academicYear}'),
            ),
            DesktopDataColumn(
              label: 'Estado',
              cellBuilder: (item) => AppStatusChip(
                label: item.active ? 'Activa' : 'Inactiva',
                kind: item.active
                    ? AppStatusKind.success
                    : AppStatusKind.neutral,
              ),
            ),
            DesktopDataColumn(
              label: 'Acciones',
              cellBuilder: (item) => AssignmentActions(item: item),
            ),
          ],
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
    return Column(
      children: [
        Expanded(child: _buildList(context, state)),
        if (state.status == ViewStatus.success)
          AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) =>
                context.read<TeachingProvider>().loadPeriods(page: page),
          ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    ListViewState<TeachingPeriodEntity> state,
  ) {
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
        return DesktopDataTable<TeachingPeriodEntity>(
          items: state.items,
          onRowTap: (item) =>
              context.push(RoutePaths.teachingPeriodDetail(item.id)),
          columns: [
            DesktopDataColumn(
              label: 'Clase',
              cellBuilder: (item) => Text(item.courseLabel),
            ),
            DesktopDataColumn(
              label: 'Materia',
              cellBuilder: (item) => SubjectBadge(
                name: item.subjectName,
                color: subjectColor(item.subjectId),
              ),
            ),
            DesktopDataColumn(
              label: 'Periodo',
              cellBuilder: (item) => Text(item.academicPeriodName),
            ),
            DesktopDataColumn(
              label: 'Fechas',
              cellBuilder: (item) => Text(
                '${Formatters.date(item.startDate)} — ${Formatters.date(item.endDate)}',
              ),
            ),
            DesktopDataColumn(
              label: 'Acciones',
              cellBuilder: (item) => IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => TeachingActions.deletePeriod(context, item),
              ),
            ),
          ],
        );
    }
  }
}
