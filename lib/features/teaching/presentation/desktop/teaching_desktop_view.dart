import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../../academic_periods/presentation/providers/academic_periods_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../subjects/presentation/providers/subjects_provider.dart';
import '../providers/teaching_provider.dart';
import '../shared/class_grouping.dart';
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

  Future<void> _addClasses(BuildContext context, {int? groupId}) async {
    final inputs = await TeachingActions.addClassesFormInputs(context);
    if (inputs == null || !context.mounted) return;
    final data = await showDesktopDialog<AddClassesResult>(
      context,
      width: 560,
      child: AddClassesForm(
        courses: inputs.courses,
        subjects: inputs.subjects,
        academicPeriods: inputs.academicPeriods,
        assignments: inputs.assignments,
        initialGroupId: groupId,
        initialAcademicPeriodId: academicPeriodId,
      ),
    );
    if (data == null || !context.mounted) return;
    await TeachingActions.addClasses(context, data);
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

    final grouping = groupClasses(
      assignments: teaching.allAssignments,
      periods: teaching.allPeriods,
      academicPeriodId: academicPeriodId,
      include: (entry, courseLabel) =>
          (filters.subjectId == null || entry.subjectId == filters.subjectId) &&
          (filters.active == null ||
              entry.assignment.active == filters.active) &&
          matchesSearch(search, [
            entry.subjectName,
            courseLabel,
            entry.assignment.gradeName,
            description(entry.subjectId),
          ]),
    );
    final groups = [
      for (final course in grouping.courses)
        ClassTableGroup(
          groupId: course.groupId,
          label: course.label,
          studentCount: course.studentCount,
          rows: [
            for (final entry in course.entries)
              ClassRowData(
                assignment: entry.assignment,
                courseLabel: course.label,
                period: entry.period,
                description: description(entry.subjectId),
                weeklySessions: entry.period == null || weekly == null
                    ? null
                    : weekly[entry.period!.id] ?? 0,
              ),
          ],
        ),
    ];
    final selected = [
      for (final g in groups) ...g.rows,
    ].where((r) => r.assignment.id == selectedAssignmentId).firstOrNull;
    final loading = switch (assignmentsState.status) {
      ViewStatus.initial || ViewStatus.loading => true,
      _ =>
        teaching.allPeriods.isEmpty &&
            switch (teaching.periodsState.status) {
              ViewStatus.initial || ViewStatus.loading => true,
              _ => false,
            },
    };

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
              grouping: loading ? null : grouping,
              academicPeriod: academicPeriod,
              onAdd: () => _addClasses(context),
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
                    _ when loading => const DesktopListTableSkeleton(
                      columns: [
                        SkeletonColumn(
                          'Materia',
                          flex: 5,
                          cell: SkeletonCell.badge,
                        ),
                        SkeletonColumn('En el periodo', flex: 3),
                        SkeletonColumn('Horario', flex: 2),
                        SkeletonColumn(
                          'Alumnos',
                          flex: 2,
                          cell: SkeletonCell.value,
                        ),
                        SkeletonColumn(
                          'Activa',
                          width: 120,
                          cell: SkeletonCell.chip,
                        ),
                      ],
                    ),
                    ViewStatus.error => AppErrorState(
                      exception: assignmentsState.error!,
                      onRetry: () =>
                          context.read<TeachingProvider>().refreshAssignments(),
                    ),
                    ViewStatus.empty => AppEmptyState(
                      title: 'Aún no tienes clases',
                      message:
                          'Agrega las materias que dictas en cada curso para '
                          'empezar.',
                      icon: Icons.groups_outlined,
                      actionLabel: 'Agregar materias',
                      onAction: () => _addClasses(context),
                    ),
                    _ when grouping.isEmpty => const AppEmptyState(
                      title: 'Sin resultados',
                      message:
                          'Ningún curso o materia coincide con los filtros.',
                      icon: Icons.search_off,
                    ),
                    _ => ClassesTable(
                      groups: groups,
                      compact: grouping.singleSubjectName != null,
                      selectedAssignmentId: selectedAssignmentId,
                      academicPeriod: academicPeriod,
                      actions: actions,
                      clickOpens: !showPreview,
                      onAddSubject: (groupId) =>
                          _addClasses(context, groupId: groupId),
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
    required this.grouping,
    required this.academicPeriod,
    required this.onAdd,
  });

  /// Null while the classes are being read.
  final ClassGrouping? grouping;
  final AcademicPeriodEntity? academicPeriod;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final grouping = this.grouping;
    final scope = academicPeriod == null
        ? 'en todos los periodos'
        : 'en ${academicPeriod!.name}';
    String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';
    final single = grouping?.singleSubjectName;
    final summary = grouping == null
        ? ''
        : single != null
        ? '$single  ·  ${count(grouping.courseCount, 'curso', 'cursos')} $scope'
        : '${count(grouping.courseCount, 'curso', 'cursos')}  ·  '
              '${count(grouping.classCount, 'clase', 'clases')} $scope';

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
                summary,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AppButton(label: 'Agregar materias', icon: Icons.add, onPressed: onAdd),
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
            hint: 'Buscar curso o materia...',
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
