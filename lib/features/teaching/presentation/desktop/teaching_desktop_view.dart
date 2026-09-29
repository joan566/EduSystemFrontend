import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../../academic_periods/presentation/providers/academic_periods_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../subjects/presentation/providers/subjects_provider.dart';
import '../providers/teaching_provider.dart';
import '../shared/class_lookup.dart';
import '../shared/teaching_actions.dart';
import '../shared/teaching_forms.dart';
import 'widgets/class_preview_panel.dart';
import 'widgets/classes_table.dart';

/// Desktop "Clases": a filter toolbar over one dense table of the
/// teacher's classes, with the selected class previewed beside it.
///
/// Unlike mobile (two tabs of cards), assignments and their class in the
/// chosen period share a row: a missing class is created inline, and
/// selection shows the class without leaving the list. The preview pane
/// only fits from [_previewMinWidth]; below it a click opens the class.
class TeachingDesktopView extends StatelessWidget {
  const TeachingDesktopView({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.academicPeriodId,
    required this.onAcademicPeriodChanged,
    required this.search,
    required this.onSearchChanged,
    required this.selectedAssignmentId,
    required this.onSelect,
  });

  final AssignmentFilters filters;
  final ValueChanged<AssignmentFilters> onFiltersChanged;
  final int? academicPeriodId;
  final ValueChanged<int?> onAcademicPeriodChanged;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final int? selectedAssignmentId;
  final ValueChanged<int?> onSelect;

  static const _previewMinWidth = 1100.0;
  static const _previewWidth = 360.0;

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
    final teaching = context.watch<TeachingProvider>();
    final academicPeriods = context
        .watch<AcademicPeriodsProvider>()
        .state
        .items;
    final subjects = context.watch<SubjectsProvider>().state.items;
    final weekly = context
        .watch<ScheduleProvider>()
        .week
        .data
        ?.occurrencesByTeachingPeriod;
    final academicPeriod = academicPeriods
        .where((p) => p.id == academicPeriodId)
        .firstOrNull;
    final assignmentsState = teaching.assignmentsState;

    String? description(int subjectId) =>
        subjects.where((s) => s.id == subjectId).firstOrNull?.description;

    final rows = [
      for (final a in assignmentsState.items)
        if (matchesSearch(search, [
          a.subjectName,
          '${a.gradeName} ${a.groupName}',
          description(a.subjectId),
        ]))
          () {
            final period = classForAssignment(
              a,
              teaching.allPeriods,
              academicPeriodId: academicPeriodId,
            );
            return ClassRowData(
              assignment: a,
              period: period,
              description: description(a.subjectId),
              weeklySessions: period == null || weekly == null
                  ? null
                  : weekly[period.id] ?? 0,
            );
          }(),
    ];
    final selected = rows
        .where((r) => r.assignment.id == selectedAssignmentId)
        .firstOrNull;
    final classesInPeriod = teaching.allPeriods
        .where(
          (p) =>
              academicPeriodId == null ||
              p.academicPeriodId == academicPeriodId,
        )
        .length;

    final actions = ClassRowActions(
      onSelect: (row) => onSelect(row.assignment.id),
      onOpen: (row) {
        final period = row.period;
        if (period != null) {
          context.push(RoutePaths.teachingPeriodDetail(period.id));
        } else {
          onSelect(row.assignment.id);
        }
      },
      onCreateClass: (row) {
        if (academicPeriod == null) return;
        TeachingActions.createClassFor(
          context,
          assignment: row.assignment,
          academicPeriod: academicPeriod,
        );
      },
      onToggleActive: (row) => TeachingActions.setAssignmentActive(
        context,
        row.assignment,
        !row.assignment.active,
      ),
      onDelete: (row) =>
          TeachingActions.deleteAssignment(context, row.assignment),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              assignments: assignmentsState.totalElements,
              classes: classesInPeriod,
              academicPeriod: academicPeriod,
              onCreateAssignment: () => _createAssignment(context),
              onCreatePeriod: () => _createPeriod(context),
            ),
            const SizedBox(height: 18),
            _Toolbar(
              search: search,
              onSearchChanged: onSearchChanged,
              academicPeriods: academicPeriods,
              academicPeriod: academicPeriod,
              onAcademicPeriodChanged: onAcademicPeriodChanged,
              subjects: subjects,
              filters: filters,
              onFiltersChanged: onFiltersChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showPreview = constraints.maxWidth >= _previewMinWidth;
                  final table = switch (assignmentsState.status) {
                    ViewStatus.initial ||
                    ViewStatus.loading => const AppLoading(),
                    ViewStatus.error => AppErrorState(
                      exception: assignmentsState.error!,
                      onRetry: () =>
                          context.read<TeachingProvider>().loadAssignments(
                            subjectId: filters.subjectId,
                            active: filters.active,
                          ),
                    ),
                    ViewStatus.empty => AppEmptyState(
                      title: 'No tienes asignaciones',
                      message:
                          'Asigna una materia a un curso para empezar a '
                          'dictar clases.',
                      icon: Icons.groups_outlined,
                      actionLabel: 'Nueva asignación',
                      onAction: () => _createAssignment(context),
                    ),
                    ViewStatus.success when rows.isEmpty => const AppEmptyState(
                      title: 'Sin resultados',
                      message: 'Ninguna clase coincide con la búsqueda.',
                      icon: Icons.search_off,
                    ),
                    ViewStatus.success => ClassesTable(
                      rows: rows,
                      selectedAssignmentId: selectedAssignmentId,
                      academicPeriod: academicPeriod,
                      actions: actions,
                      clickOpens: !showPreview,
                    ),
                  };
                  if (!showPreview) return table;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: table),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: _previewWidth,
                        child: ClassPreviewPanel(
                          row: selected,
                          academicPeriod: academicPeriod,
                          onCreateClass: () {
                            if (selected != null) {
                              actions.onCreateClass(selected);
                            }
                          },
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

class _Header extends StatelessWidget {
  const _Header({
    required this.assignments,
    required this.classes,
    required this.academicPeriod,
    required this.onCreateAssignment,
    required this.onCreatePeriod,
  });

  final int assignments;
  final int classes;
  final AcademicPeriodEntity? academicPeriod;
  final VoidCallback onCreateAssignment;
  final VoidCallback onCreatePeriod;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scope = academicPeriod == null
        ? 'en todos los periodos'
        : 'en ${academicPeriod!.name}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Clases', style: textTheme.headlineLarge),
              const SizedBox(height: 2),
              Text(
                '$assignments asignaciones  ·  $classes clases $scope',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AppButton(
          label: 'Nueva asignación',
          icon: Icons.add,
          variant: AppButtonVariant.outlined,
          onPressed: onCreateAssignment,
        ),
        const SizedBox(width: 10),
        AppButton(
          label: 'Nueva clase',
          icon: Icons.add,
          onPressed: onCreatePeriod,
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.search,
    required this.onSearchChanged,
    required this.academicPeriods,
    required this.academicPeriod,
    required this.onAcademicPeriodChanged,
    required this.subjects,
    required this.filters,
    required this.onFiltersChanged,
  });

  final String search;
  final ValueChanged<String> onSearchChanged;
  final List<AcademicPeriodEntity> academicPeriods;
  final AcademicPeriodEntity? academicPeriod;
  final ValueChanged<int?> onAcademicPeriodChanged;
  final List<SubjectEntity> subjects;
  final AssignmentFilters filters;
  final ValueChanged<AssignmentFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: AppSearchField(
            hint: 'Buscar materia, grado o clase...',
            initialValue: search,
            onChanged: onSearchChanged,
          ),
        ),
        SizedBox(
          width: 190,
          child: AppDropdown<AcademicPeriodEntity?>(
            label: 'Periodo',
            value: academicPeriod,
            items: [null, ...academicPeriods],
            itemLabel: (p) => p?.name ?? 'Todos los periodos',
            onChanged: (p) => onAcademicPeriodChanged(p?.id),
          ),
        ),
        SizedBox(
          width: 210,
          child: AppDropdown<SubjectEntity?>(
            label: 'Materia',
            value: subjects.where((s) => s.id == filters.subjectId).firstOrNull,
            items: [null, ...subjects],
            itemLabel: (s) => s?.name ?? 'Todas las materias',
            onChanged: (s) => onFiltersChanged(
              AssignmentFilters(subjectId: s?.id, active: filters.active),
            ),
          ),
        ),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0, label: Text('Todas')),
            ButtonSegment(value: 1, label: Text('Activas')),
            ButtonSegment(value: 2, label: Text('Inactivas')),
          ],
          selected: {
            switch (filters.active) {
              null => 0,
              true => 1,
              false => 2,
            },
          },
          onSelectionChanged: (value) => onFiltersChanged(
            AssignmentFilters(
              subjectId: filters.subjectId,
              active: switch (value.first) {
                1 => true,
                2 => false,
                _ => null,
              },
            ),
          ),
        ),
      ],
    );
  }
}
