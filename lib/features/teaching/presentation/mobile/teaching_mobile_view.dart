import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/mobile/mobile_brand_bar.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_header_action.dart';
import '../../../../core/widgets/mobile/mobile_select_field.dart';
import '../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../../academic_periods/presentation/providers/academic_periods_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../subjects/presentation/providers/subjects_provider.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';
import '../shared/class_lookup.dart';
import '../shared/teaching_actions.dart';
import '../shared/teaching_forms.dart';
import 'widgets/class_list_card.dart';

/// Mobile "Clases": brand bar, title with counts, search + status filter,
/// period and subject pickers, then "Mis clases" (assignments) and "Por
/// periodo" (classes of the chosen academic period) as card lists.
class TeachingMobileView extends StatelessWidget {
  const TeachingMobileView({
    super.key,
    required this.tabController,
    required this.filters,
    required this.onFiltersChanged,
    required this.academicPeriodId,
    required this.onAcademicPeriodChanged,
    required this.search,
    required this.onSearchChanged,
  });

  final TabController tabController;
  final AssignmentFilters filters;
  final ValueChanged<AssignmentFilters> onFiltersChanged;
  final int? academicPeriodId;
  final ValueChanged<int?> onAcademicPeriodChanged;
  final String search;
  final ValueChanged<String> onSearchChanged;

  Future<void> _createAssignment(BuildContext context) async {
    final inputs = await TeachingActions.assignmentFormInputs(context);
    if (inputs == null || !context.mounted) return;
    final data = await showMobileForm<AssignmentFormResult>(
      context,
      child: AssignmentForm(subjects: inputs.subjects, courses: inputs.courses),
    );
    if (data == null || !context.mounted) return;
    await TeachingActions.createAssignment(context, data);
  }

  Future<void> _createPeriod(BuildContext context) async {
    final inputs = await TeachingActions.periodFormInputs(context);
    if (inputs == null || !context.mounted) return;
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

  Future<void> _openCreateMenu(BuildContext context) async {
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Nueva asignación'),
              subtitle: const Text('Una materia en un curso'),
              onTap: () => Navigator.of(context).pop(0),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Nueva clase por periodo'),
              subtitle: const Text('Una asignación en un periodo académico'),
              onTap: () => Navigator.of(context).pop(1),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 0:
        await _createAssignment(context);
      case 1:
        await _createPeriod(context);
    }
  }

  Future<void> _openStatusFilter(BuildContext context) async {
    final picked = await showMobileSheet<({bool? active})>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Estado de la asignación',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final (value, label) in const [
              (null, 'Todas'),
              (true, 'Activas'),
              (false, 'Inactivas'),
            ])
              ListTile(
                title: Text(label),
                trailing: filters.active == value
                    ? const Icon(Icons.check, color: AppColors.accentBlue)
                    : null,
                onTap: () => Navigator.of(context).pop((active: value)),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    onFiltersChanged(
      AssignmentFilters(subjectId: filters.subjectId, active: picked.active),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teaching = context.watch<TeachingProvider>();
    final academicPeriods = context
        .watch<AcademicPeriodsProvider>()
        .state
        .items;
    final subjects = context.watch<SubjectsProvider>().state.items;
    final classes = _classesInPeriod(teaching.allPeriods);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MobileBrandBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clases',
                        style: textTheme.headlineLarge?.copyWith(fontSize: 26),
                      ),
                      Text(
                        '${teaching.assignments(subjectId: filters.subjectId, active: filters.active).totalElements} asignaciones'
                        '  ·  ${classes.length} clases por periodo',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                MobileHeaderAction(
                  icon: Icons.add,
                  tooltip: 'Crear',
                  onPressed: () => _openCreateMenu(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchField(
                    hint: 'Buscar materia, grado o clase...',
                    initialValue: search,
                    onChanged: onSearchChanged,
                  ),
                ),
                const SizedBox(width: 10),
                _StatusFilterButton(
                  active: filters.active != null,
                  onPressed: () => _openStatusFilter(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: MobileSelectField<AcademicPeriodEntity?>(
                    icon: Icons.calendar_month_outlined,
                    label: 'Periodo',
                    value: academicPeriods
                        .where((p) => p.id == academicPeriodId)
                        .firstOrNull,
                    options: [null, ...academicPeriods],
                    itemLabel: (p) => p?.name ?? 'Todos',
                    onChanged: (p) => onAcademicPeriodChanged(p?.id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MobileSelectField<SubjectEntity?>(
                    icon: Icons.menu_book_outlined,
                    label: 'Materia',
                    value: subjects
                        .where((s) => s.id == filters.subjectId)
                        .firstOrNull,
                    options: [null, ...subjects],
                    itemLabel: (s) => s?.name ?? 'Todas',
                    onChanged: (s) => onFiltersChanged(
                      AssignmentFilters(
                        subjectId: s?.id,
                        active: filters.active,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: tabController,
            labelColor: AppColors.textPrimary,
            indicatorColor: AppColors.accentBlue,
            indicatorWeight: 3,
            dividerColor: Theme.of(context).colorScheme.outline,
            labelStyle: textTheme.labelLarge,
            tabs: const [
              Tab(text: 'Mis clases'),
              Tab(text: 'Por periodo'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _AssignmentsTab(
                  classes: teaching.allPeriods,
                  academicPeriod: academicPeriods
                      .where((p) => p.id == academicPeriodId)
                      .firstOrNull,
                  subjects: subjects,
                  search: search,
                  filters: filters,
                  onCreate: () => _createAssignment(context),
                ),
                _ClassesTab(
                  loading: switch (teaching.periodsState.status) {
                    ViewStatus.initial || ViewStatus.loading => true,
                    _ => false,
                  },
                  classes: _filtered(classes, subjects),
                  subjects: subjects,
                  onCreate: () => _createPeriod(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TeachingPeriodEntity> _classesInPeriod(List<TeachingPeriodEntity> all) =>
      academicPeriodId == null
      ? all
      : all.where((p) => p.academicPeriodId == academicPeriodId).toList();

  List<TeachingPeriodEntity> _filtered(
    List<TeachingPeriodEntity> classes,
    List<SubjectEntity> subjects,
  ) =>
      classes
          .where(
            (p) =>
                filters.subjectId == null || p.subjectId == filters.subjectId,
          )
          .where(
            (p) => matchesSearch(search, [
              p.subjectName,
              p.courseLabel,
              p.academicPeriodName,
              _subjectDescription(subjects, p.subjectId),
            ]),
          )
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
}

String? _subjectDescription(List<SubjectEntity> subjects, int subjectId) =>
    subjects.where((s) => s.id == subjectId).firstOrNull?.description;

class _StatusFilterButton extends StatelessWidget {
  const _StatusFilterButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Badge(
      isLabelVisible: active,
      smallSize: 8,
      backgroundColor: AppColors.accentBlue,
      child: IconButton.outlined(
        tooltip: 'Filtrar por estado',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          side: BorderSide(color: colors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.tune),
      ),
    );
  }
}

/// "Mis clases": the teacher's assignments. Counts and the tap target come
/// from the assignment's class in the chosen academic period.
class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({
    required this.classes,
    required this.academicPeriod,
    required this.subjects,
    required this.search,
    required this.filters,
    required this.onCreate,
  });

  final List<TeachingPeriodEntity> classes;
  final AcademicPeriodEntity? academicPeriod;
  final List<SubjectEntity> subjects;
  final String search;
  final AssignmentFilters filters;
  final VoidCallback onCreate;

  Future<void> _openActions(
    BuildContext context,
    TeachingAssignmentEntity item,
  ) async {
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                item.active ? Icons.toggle_off_outlined : Icons.toggle_on,
              ),
              title: Text(
                item.active ? 'Desactivar asignación' : 'Activar asignación',
              ),
              onTap: () => Navigator.of(context).pop(0),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Eliminar asignación'),
              onTap: () => Navigator.of(context).pop(1),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 0:
        await TeachingActions.setAssignmentActive(context, item, !item.active);
      case 1:
        await TeachingActions.deleteAssignment(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().assignments(
      subjectId: filters.subjectId,
      active: filters.active,
    );
    final weekly = context
        .watch<ScheduleProvider>()
        .week
        .data
        ?.occurrencesByTeachingPeriod;

    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const MobileListSkeleton(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
          leading: SkeletonLeading.square,
          leadingSize: 56,
          trailingWidth: 60,
          meta: true,
        );
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<TeachingProvider>().refreshAssignments(),
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
        final items = state.items
            .where(
              (a) => matchesSearch(search, [
                a.subjectName,
                a.gradeName,
                a.groupName,
                '${a.gradeName} ${a.groupName}',
                _subjectDescription(subjects, a.subjectId),
              ]),
            )
            .toList();
        if (items.isEmpty) {
          return const AppEmptyState(
            title: 'Sin resultados',
            message: 'Ninguna asignación coincide con la búsqueda.',
            icon: Icons.search_off,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            final period = classForAssignment(
              item,
              classes,
              academicPeriodId: academicPeriod?.id,
            );
            return ClassListCard(
              title:
                  '${item.subjectName} — ${item.gradeName} ${item.groupName}',
              subtitle: _subjectDescription(subjects, item.subjectId),
              color: subjectAccent(item.subjectId),
              status: AppStatusChip(
                label: item.active ? 'Activa' : 'Inactiva',
                kind: item.active
                    ? AppStatusKind.success
                    : AppStatusKind.neutral,
              ),
              students: period?.studentCount,
              weeklySessions: period == null || weekly == null
                  ? null
                  : weekly[period.id] ?? 0,
              footnote: academicPeriod == null
                  ? 'Sin clases por periodo'
                  : 'Sin clase en ${academicPeriod!.name}',
              onTap: () {
                if (period != null) {
                  context.push(RoutePaths.teachingPeriodDetail(period.id));
                } else {
                  context.showInfo(
                    academicPeriod == null
                        ? 'Esta asignación aún no tiene clases por periodo.'
                        : 'Esta asignación no tiene clase en '
                              '${academicPeriod!.name}. Créala desde el botón +.',
                  );
                }
              },
              onLongPress: () => _openActions(context, item),
            );
          },
        );
    }
  }
}

/// "Por periodo": the classes of the chosen academic period.
class _ClassesTab extends StatelessWidget {
  const _ClassesTab({
    required this.loading,
    required this.classes,
    required this.subjects,
    required this.onCreate,
  });

  /// The class catalog is still being read: not the same as no classes.
  final bool loading;
  final List<TeachingPeriodEntity> classes;
  final List<SubjectEntity> subjects;
  final VoidCallback onCreate;

  Future<void> _openActions(
    BuildContext context,
    TeachingPeriodEntity item,
  ) async {
    final delete = await showMobileSheet<bool>(
      context,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          title: const Text('Eliminar clase'),
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (delete == true && context.mounted) {
      await TeachingActions.deletePeriod(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekly = context
        .watch<ScheduleProvider>()
        .week
        .data
        ?.occurrencesByTeachingPeriod;
    final now = DateTime.now();

    if (loading) {
      return const MobileListSkeleton(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
        leading: SkeletonLeading.square,
        leadingSize: 56,
        trailingWidth: 60,
        meta: true,
      );
    }
    if (classes.isEmpty) {
      return AppEmptyState(
        title: 'Sin clases en este periodo',
        message:
            'Vincula una asignación con un periodo académico para empezar.',
        icon: Icons.calendar_month_outlined,
        actionLabel: 'Nueva clase',
        onAction: onCreate,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: classes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = classes[index];
        final (label, kind) = switch (classPeriodStatus(item, now)) {
          ClassPeriodStatus.active => ('En curso', AppStatusKind.success),
          ClassPeriodStatus.upcoming => ('Próxima', AppStatusKind.info),
          ClassPeriodStatus.finished => ('Finalizada', AppStatusKind.neutral),
        };
        return ClassListCard(
          title: '${item.subjectName} — ${item.courseLabel}',
          subtitle:
              _subjectDescription(subjects, item.subjectId) ??
              item.academicPeriodName,
          color: subjectAccent(item.subjectId),
          status: AppStatusChip(label: label, kind: kind),
          students: item.studentCount,
          weeklySessions: weekly == null ? null : weekly[item.id] ?? 0,
          onTap: () => context.push(RoutePaths.teachingPeriodDetail(item.id)),
          onLongPress: () => _openActions(context, item),
        );
      },
    );
  }
}
