import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_hero_banner.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_pagination.dart';
import '../../../../core/widgets/app_stat_card.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../../academic_periods/presentation/providers/academic_periods_provider.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../subjects/presentation/providers/subjects_provider.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';

/// Deterministic per-subject accent, cycling through the existing semantic
/// palette (no new colors) so classes read apart from each other in lists
/// the way the reference design's colored subject badges do.
const _subjectPalette = [
  AppColors.primary,
  AppColors.info,
  AppColors.success,
  AppColors.warning,
  AppColors.error,
  AppColors.primaryMedium,
];

Color _subjectColor(int subjectId) =>
    _subjectPalette[subjectId % _subjectPalette.length];

class TeachingPage extends StatefulWidget {
  const TeachingPage({super.key});

  @override
  State<TeachingPage> createState() => _TeachingPageState();
}

class _TeachingPageState extends State<TeachingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeachingProvider>().loadAssignments();
      context.read<TeachingProvider>().loadPeriods();
      // Needed for the "Materia" filter and the create-assignment form —
      // load once up front instead of assuming the user already visited
      // the Subjects page this session.
      final subjects = context.read<SubjectsProvider>();
      if (subjects.state.status == ViewStatus.initial) subjects.load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _createAssignment() async {
    final subjects = context.read<SubjectsProvider>().state.items;
    final courses = context.read<CoursesProvider>().state.items;
    if (subjects.isEmpty || courses.isEmpty) {
      context.showWarning('Necesitas al menos una materia y un curso creados.');
      return;
    }
    final result = await showAppDialog(
      context,
      child: _AssignmentForm(subjects: subjects, courses: courses),
    );
    if (result == null) return;
    final data = result as ({int groupId, int subjectId});
    final error = await context.read<TeachingProvider>().createAssignment(
      groupId: data.groupId,
      subjectId: data.subjectId,
    );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Asignación creada.');
    }
  }

  Future<void> _createPeriod(List<TeachingAssignmentEntity> assignments) async {
    final periods = context.read<AcademicPeriodsProvider>().state.items;
    final activeAssignments = assignments.where((a) => a.active).toList();
    if (activeAssignments.isEmpty || periods.isEmpty) {
      context.showWarning(
        'Necesitas una asignación activa y un periodo académico creados.',
      );
      return;
    }
    final result = await showAppDialog(
      context,
      child: _PeriodForm(assignments: activeAssignments, periods: periods),
    );
    if (result == null) return;
    final data = result as ({int teachingAssignmentId, int academicPeriodId});
    final error = await context.read<TeachingProvider>().createPeriod(
      teachingAssignmentId: data.teachingAssignmentId,
      academicPeriodId: data.academicPeriodId,
    );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Clase creada.');
    }
  }

  void _createPeriodFromCurrentAssignments() {
    final assignments = context.read<TeachingProvider>().assignmentsState.items;
    _createPeriod(assignments);
  }

  @override
  Widget build(BuildContext context) {
    final onAssignmentsTab = _tabController.index == 0;
    final onCreate = onAssignmentsTab
        ? _createAssignment
        : _createPeriodFromCurrentAssignments;
    final assignmentsState = context.watch<TeachingProvider>().assignmentsState;
    final periodsState = context.watch<TeachingProvider>().periodsState;

    return Scaffold(
      floatingActionButton: context.isMobile
          ? FloatingActionButton(
              onPressed: onCreate,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.isMobile ? 16 : 24,
              20,
              context.isMobile ? 16 : 24,
              0,
            ),
            child: Column(
              children: [
                AppHeroBanner(
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
                  onCtaPressed: onCreate,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        label: 'Asignaciones',
                        value: '${assignmentsState.totalElements}',
                        hasError: assignmentsState.status == ViewStatus.error,
                        icon: Icons.groups_outlined,
                        accentColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppStatCard(
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
            controller: _tabController,
            tabs: const [
              Tab(text: 'Asignaciones'),
              Tab(text: 'Clases por periodo'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AssignmentsTab(onCreate: _createAssignment),
                _PeriodsTab(onCreate: _createPeriodFromCurrentAssignments),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsTab extends StatefulWidget {
  const _AssignmentsTab({required this.onCreate});

  final VoidCallback onCreate;

  @override
  State<_AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<_AssignmentsTab> {
  int? _subjectFilter;
  bool? _activeFilter;

  void _applyFilters() {
    context.read<TeachingProvider>().loadAssignments(
      page: 0,
      subjectId: _subjectFilter,
      active: _activeFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().assignmentsState;
    final subjects = context.watch<SubjectsProvider>().state.items;

    return Column(
      children: [
        if (subjects.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.isMobile ? 16 : 24,
              12,
              context.isMobile ? 16 : 24,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppDropdown<SubjectEntity?>(
                    label: 'Materia',
                    value: subjects
                        .where((s) => s.id == _subjectFilter)
                        .firstOrNull,
                    items: [null, ...subjects],
                    itemLabel: (s) => s?.name ?? 'Todas las materias',
                    onChanged: (s) {
                      setState(() => _subjectFilter = s?.id);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown<bool?>(
                    label: 'Estado',
                    value: _activeFilter,
                    items: const [null, true, false],
                    itemLabel: (v) => switch (v) {
                      null => 'Todas',
                      true => 'Activas',
                      false => 'Inactivas',
                    },
                    onChanged: (v) {
                      setState(() => _activeFilter = v);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: _buildList(context, state)),
        if (state.status == ViewStatus.success)
          AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) => context.read<TeachingProvider>().loadAssignments(
              page: page,
              subjectId: _subjectFilter,
              active: _activeFilter,
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
          onAction: widget.onCreate,
        );
      case ViewStatus.success:
        return AppDataTable<TeachingAssignmentEntity>(
          isMobile: context.isMobile,
          items: state.items,
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.groups_outlined,
            iconColor: _subjectColor(item.subjectId),
            title: item.displayName,
            subtitle: 'Año académico ${item.academicYear}',
            trailing: _AssignmentActions(item: item),
          ),
          columns: [
            AppDataColumn(
              label: 'Clase',
              cellBuilder: (item) => Text(item.displayName),
            ),
            AppDataColumn(
              label: 'Materia',
              cellBuilder: (item) => _SubjectBadge(
                name: item.subjectName,
                color: _subjectColor(item.subjectId),
              ),
            ),
            AppDataColumn(
              label: 'Año académico',
              cellBuilder: (item) => Text('${item.academicYear}'),
            ),
            AppDataColumn(
              label: 'Estado',
              cellBuilder: (item) => AppStatusChip(
                label: item.active ? 'Activa' : 'Inactiva',
                kind: item.active ? AppStatusKind.success : AppStatusKind.neutral,
              ),
            ),
            AppDataColumn(
              label: 'Acciones',
              cellBuilder: (item) => _AssignmentActions(item: item),
            ),
          ],
        );
    }
  }
}

class _SubjectBadge extends StatelessWidget {
  const _SubjectBadge({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _AssignmentActions extends StatelessWidget {
  const _AssignmentActions({required this.item});

  final TeachingAssignmentEntity item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: item.active,
          onChanged: (value) async {
            final error = await context
                .read<TeachingProvider>()
                .setAssignmentActive(item.id, value);
            if (context.mounted && error != null) context.showApiError(error);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: () async {
            final confirmed = await showAppConfirmDialog(
              context,
              title: 'Eliminar asignación',
              message: 'Esta acción no se puede deshacer.',
              confirmLabel: 'Eliminar',
            );
            if (!confirmed || !context.mounted) return;
            final error = await context
                .read<TeachingProvider>()
                .deleteAssignment(item.id);
            if (context.mounted && error != null) context.showApiError(error);
          },
        ),
      ],
    );
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
        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: context.isMobile ? 16 : 24,
            vertical: 8,
          ),
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = state.items[index];
            return AppListTile(
              icon: Icons.calendar_month_outlined,
              iconColor: _subjectColor(item.subjectId),
              title: item.displayName,
              subtitle:
                  '${Formatters.date(item.startDate)} — ${Formatters.date(item.endDate)}',
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () async {
                  final confirmed = await showAppConfirmDialog(
                    context,
                    title: 'Eliminar clase',
                    message: 'Esta acción no se puede deshacer.',
                    confirmLabel: 'Eliminar',
                  );
                  if (!confirmed || !context.mounted) return;
                  final error = await context
                      .read<TeachingProvider>()
                      .deletePeriod(item.id);
                  if (context.mounted && error != null)
                    context.showApiError(error);
                },
              ),
            );
          },
        );
    }
  }
}

class _AssignmentForm extends StatefulWidget {
  const _AssignmentForm({required this.subjects, required this.courses});

  final List<SubjectEntity> subjects;
  final List<CourseEntity> courses;

  @override
  State<_AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<_AssignmentForm> {
  final _formKey = GlobalKey<FormState>();
  int? _subjectId;
  int? _groupId;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.subjects.first.id;
    _groupId = widget.courses.first.id;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((groupId: _groupId!, subjectId: _subjectId!));
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Nueva asignación',
      actions: [AppButton(label: 'Guardar', onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<int>(
              label: 'Materia',
              required: true,
              value: _subjectId,
              items: [for (final s in widget.subjects) s.id],
              itemLabel: (id) =>
                  widget.subjects.firstWhere((s) => s.id == id).name,
              validator: (v) => v == null ? 'Selecciona una materia.' : null,
              onChanged: (value) => setState(() => _subjectId = value),
            ),
            const SizedBox(height: 16),
            AppDropdown<int>(
              label: 'Curso',
              required: true,
              value: _groupId,
              items: [for (final c in widget.courses) c.id],
              itemLabel: (id) =>
                  widget.courses.firstWhere((c) => c.id == id).displayName,
              validator: (v) => v == null ? 'Selecciona un curso.' : null,
              onChanged: (value) => setState(() => _groupId = value),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodForm extends StatefulWidget {
  const _PeriodForm({required this.assignments, required this.periods});

  final List<TeachingAssignmentEntity> assignments;
  final List<AcademicPeriodEntity> periods;

  @override
  State<_PeriodForm> createState() => _PeriodFormState();
}

class _PeriodFormState extends State<_PeriodForm> {
  final _formKey = GlobalKey<FormState>();
  int? _assignmentId;
  int? _periodId;

  @override
  void initState() {
    super.initState();
    _assignmentId = widget.assignments.first.id;
    _periodId = widget.periods.first.id;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      teachingAssignmentId: _assignmentId!,
      academicPeriodId: _periodId!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Nueva clase',
      actions: [AppButton(label: 'Guardar', onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<int>(
              label: 'Asignación',
              required: true,
              value: _assignmentId,
              items: [for (final a in widget.assignments) a.id],
              itemLabel: (id) =>
                  widget.assignments.firstWhere((a) => a.id == id).displayName,
              validator: (v) => v == null ? 'Selecciona una asignación.' : null,
              onChanged: (value) => setState(() => _assignmentId = value),
            ),
            const SizedBox(height: 16),
            AppDropdown<int>(
              label: 'Periodo académico',
              required: true,
              value: _periodId,
              items: [for (final p in widget.periods) p.id],
              itemLabel: (id) =>
                  widget.periods.firstWhere((p) => p.id == id).name,
              validator: (v) => v == null ? 'Selecciona un periodo.' : null,
              onChanged: (value) => setState(() => _periodId = value),
            ),
          ],
        ),
      ),
    );
  }
}
