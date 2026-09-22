import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_pagination.dart';
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

/// Same catalog skeleton as Subjects/Courses/Periods/Levels (§18): the
/// primary action lives in the header (desktop) / FAB (mobile), not loose
/// inside the tab body — it just tracks which of the two tabs is active to
/// know which action to offer.
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

    return Scaffold(
      floatingActionButton: context.isMobile
          ? FloatingActionButton(
              onPressed: onCreate,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Mis clases',
            subtitle: 'Asignaturas que impartes y sus periodos de enseñanza.',
            actions: context.isMobile
                ? []
                : [
                    AppButton(
                      label: onAssignmentsTab ? 'Nueva asignación' : 'Nueva clase',
                      icon: Icons.add,
                      onPressed: onCreate,
                    ),
                  ],
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

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().assignmentsState;
    return Column(
      children: [
        Expanded(child: _buildList(context, state)),
        if (state.status == ViewStatus.success)
          AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) =>
                context.read<TeachingProvider>().loadAssignments(page: page),
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
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = state.items[index];
            return AppListTile(
              icon: Icons.groups_outlined,
              title: item.displayName,
              subtitle: 'Año académico ${item.academicYear}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppStatusChip(
                    label: item.active ? 'Activa' : 'Inactiva',
                    kind: item.active
                        ? AppStatusKind.success
                        : AppStatusKind.neutral,
                  ),
                  Switch(
                    value: item.active,
                    onChanged: (value) async {
                      final error = await context
                          .read<TeachingProvider>()
                          .setAssignmentActive(item.id, value);
                      if (context.mounted && error != null)
                        context.showApiError(error);
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
                      if (context.mounted && error != null)
                        context.showApiError(error);
                    },
                  ),
                ],
              ),
            );
          },
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
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = state.items[index];
            return AppListTile(
              icon: Icons.calendar_month_outlined,
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
