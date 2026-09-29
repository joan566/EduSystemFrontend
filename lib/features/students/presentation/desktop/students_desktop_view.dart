import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';
import '../shared/student_detail_widgets.dart';
import '../shared/student_list_filters.dart';
import 'widgets/student_preview_panel.dart';
import 'widgets/students_table.dart';

/// Desktop "Estudiantes": a filter toolbar over one dense table, with the
/// selected student previewed beside it (contact, current course, their
/// grades in that course) so most look-ups never leave the list.
///
/// Unlike mobile (cards, pills and sheets), filters are all visible at
/// once and rows are keyboard-navigable. The preview pane only fits from
/// [_previewMinWidth]; below it a click opens the student.
class StudentsDesktopView extends StatelessWidget {
  const StudentsDesktopView({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.selectedStudentId,
    required this.onSelect,
  });

  final StudentListFilters filters;
  final ValueChanged<StudentListFilters> onFiltersChanged;
  final int? selectedStudentId;
  final ValueChanged<int?> onSelect;

  static const _previewMinWidth = 1100.0;
  static const _previewWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().state;
    final courses = teacherCourses(
      context.watch<TeachingProvider>().allPeriods,
    );
    final students = filters.apply(state.items);
    final selected = students
        .where((s) => s.id == selectedStudentId)
        .firstOrNull;

    final actions = StudentRowActions(
      onSelect: (student) => onSelect(student.id),
      onOpen: (student, {tab}) =>
          context.push(RoutePaths.studentDetail(student.id, tab: tab)),
      onCopy: (label, value) =>
          StudentDetailActions.copy(context, label, value),
      onWithdraw: (student) => StudentDetailActions.withdraw(
        context,
        studentId: student.id,
        enrollment: student.currentEnrollment!,
      ),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(state: state, courses: courses, filters: filters),
            const SizedBox(height: 18),
            _Toolbar(
              courses: courses,
              filters: filters,
              onFiltersChanged: onFiltersChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showPreview = constraints.maxWidth >= _previewMinWidth;
                  final table = _body(
                    context,
                    state: state,
                    students: students,
                    actions: actions,
                    clickOpens: !showPreview,
                  );
                  if (!showPreview) return table;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: table),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: _previewWidth,
                        child: StudentPreviewPanel(
                          student: selected,
                          actions: actions,
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

  Widget _body(
    BuildContext context, {
    required ListViewState<StudentEntity> state,
    required List<StudentEntity> students,
    required StudentRowActions actions,
    required bool clickOpens,
  }) {
    final unfiltered = filters.groupId == null && filters.search.isEmpty;
    return switch (state.status) {
      ViewStatus.initial || ViewStatus.loading => const AppLoading(),
      ViewStatus.error => AppErrorState(
        exception: state.error!,
        onRetry: () => context.read<StudentsProvider>().load(),
      ),
      ViewStatus.empty when unfiltered => AppEmptyState(
        title: 'No tienes estudiantes registrados',
        message: 'Importa tu lista de estudiantes desde Excel para comenzar.',
        icon: Icons.people_alt_outlined,
        actionLabel: 'Importar estudiantes',
        onAction: () => context.push(RoutePaths.dataManagement),
      ),
      ViewStatus.empty => const AppEmptyState(
        title: 'Sin resultados',
        message: 'Ningún estudiante coincide con la búsqueda o el curso.',
        icon: Icons.search_off,
      ),
      ViewStatus.success when students.isEmpty => const AppEmptyState(
        title: 'Sin resultados',
        message: 'Ningún estudiante de esta página tiene ese estado.',
        icon: Icons.filter_alt_off_outlined,
      ),
      ViewStatus.success => StudentsTable(
        students: students,
        selectedStudentId: selectedStudentId,
        actions: actions,
        clickOpens: clickOpens,
        footer: state.totalPages > 1
            ? AppPagination(
                page: state.page,
                totalPages: state.totalPages,
                totalElements: state.totalElements,
                onPageChanged: (page) =>
                    context.read<StudentsProvider>().load(page: page),
              )
            : null,
      ),
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.courses,
    required this.filters,
  });

  final ListViewState<StudentEntity> state;
  final List<CourseOption> courses;
  final StudentListFilters filters;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final course = courses
        .where((c) => c.groupId == filters.groupId)
        .firstOrNull;
    final total = state.totalElements;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estudiantes', style: textTheme.headlineLarge),
              const SizedBox(height: 2),
              Text(
                state.status != ViewStatus.success
                    ? 'Los estudiantes de tus cursos.'
                    : '$total ${total == 1 ? 'estudiante' : 'estudiantes'}'
                          '${course == null ? ' en tus cursos' : ' en ${course.label}'}'
                          '  ·  ${courses.length} cursos',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AppButton(
          label: 'Importar estudiantes',
          icon: Icons.upload_file_outlined,
          onPressed: () => context.push(RoutePaths.dataManagement),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.courses,
    required this.filters,
    required this.onFiltersChanged,
  });

  final List<CourseOption> courses;
  final StudentListFilters filters;
  final ValueChanged<StudentListFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: AppSearchField(
            hint: 'Buscar por nombre, código o identificación...',
            initialValue: filters.search,
            onChanged: (search) =>
                onFiltersChanged(filters.copyWith(search: search)),
          ),
        ),
        SizedBox(
          width: 200,
          child: AppDropdown<int?>(
            label: 'Curso',
            value: filters.groupId,
            // The chosen course stays an option even before the teacher's
            // classes have loaded.
            items: {
              null,
              for (final c in courses) c.groupId,
              filters.groupId,
            }.toList(),
            itemLabel: (id) => id == null
                ? 'Todos los cursos'
                : courses.where((c) => c.groupId == id).firstOrNull?.label ??
                      'Curso',
            onChanged: (id) =>
                onFiltersChanged(filters.copyWith(groupId: () => id)),
          ),
        ),
        SegmentedButton<StudentStatusFilter>(
          showSelectedIcon: false,
          segments: [
            for (final status in StudentStatusFilter.values)
              ButtonSegment(
                value: status,
                label: Text(studentStatusLabel(status)),
              ),
          ],
          selected: {filters.status},
          onSelectionChanged: (value) =>
              onFiltersChanged(filters.copyWith(status: value.first)),
        ),
        SizedBox(
          width: 210,
          child: AppDropdown<StudentSort>(
            label: 'Ordenar',
            value: filters.sort,
            items: StudentSort.values,
            itemLabel: studentSortLabel,
            onChanged: (sort) {
              if (sort != null) onFiltersChanged(filters.copyWith(sort: sort));
            },
          ),
        ),
      ],
    );
  }
}
