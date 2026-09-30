import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_header_action.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';
import '../shared/student_list_filters.dart';
import 'widgets/student_list_card.dart';

/// Mobile "Estudiantes": title + import, search, course pills with a
/// status filter, count + order, then one card per student.
class StudentsMobileView extends StatelessWidget {
  const StudentsMobileView({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.page,
    required this.onPageChanged,
  });

  final StudentListFilters filters;
  final ValueChanged<StudentListFilters> onFiltersChanged;

  /// Page of the server listing (owned by the page entry point).
  final int page;
  final ValueChanged<int> onPageChanged;

  Future<void> _openStatusFilter(BuildContext context) async {
    final picked = await showMobileSheet<StudentStatusFilter>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Estado en el curso',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final status in StudentStatusFilter.values)
              ListTile(
                title: Text(studentStatusLabel(status)),
                trailing: filters.status == status
                    ? const Icon(Icons.check, color: AppColors.accentBlue)
                    : null,
                onTap: () => Navigator.of(context).pop(status),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onFiltersChanged(filters.copyWith(status: picked));
  }

  Future<void> _openSort(BuildContext context) async {
    final picked = await showMobileSheet<StudentSort>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Ordenar por',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final sort in StudentSort.values)
              ListTile(
                title: Text(studentSortLabel(sort)),
                trailing: filters.sort == sort
                    ? const Icon(Icons.check, color: AppColors.accentBlue)
                    : null,
                onTap: () => Navigator.of(context).pop(sort),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onFiltersChanged(filters.copyWith(sort: picked));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>().query(
      StudentsProvider.queryOf(
        page: page,
        groupId: filters.groupId,
        search: filters.search,
      ),
    );
    final courses = teacherCourses(
      context.watch<TeachingProvider>().allPeriods,
    );
    final textTheme = Theme.of(context).textTheme;
    final students = filters.apply(state.items);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
            child: Row(
              children: [
                if (Navigator.of(context).canPop())
                  const BackButton()
                else
                  const SizedBox(width: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Estudiantes',
                    style: textTheme.headlineLarge?.copyWith(fontSize: 26),
                  ),
                ),
                MobileHeaderAction(
                  icon: Icons.person_add_alt_outlined,
                  tooltip: 'Importar estudiantes',
                  onPressed: () => context.push(RoutePaths.dataManagement),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppSearchField(
              hint: 'Buscar por nombre, código o identificación...',
              initialValue: filters.search,
              onChanged: (search) =>
                  onFiltersChanged(filters.copyWith(search: search)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      children: [
                        for (final (groupId, label) in [
                          (null, 'Todos'),
                          for (final c in courses) (c.groupId, c.label),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _Pill(
                              label: label,
                              selected: filters.groupId == groupId,
                              onTap: () => onFiltersChanged(
                                filters.copyWith(groupId: () => groupId),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Badge(
                    isLabelVisible: filters.status != StudentStatusFilter.all,
                    smallSize: 8,
                    backgroundColor: AppColors.accentBlue,
                    child: IconButton(
                      tooltip: 'Filtrar por estado',
                      onPressed: () => _openStatusFilter(context),
                      icon: const Icon(Icons.tune),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.status == ViewStatus.success
                        ? _countLabel(students.length, state.totalElements)
                        : '',
                    style: textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => _openSort(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        studentSortLabel(filters.sort),
                        style: textTheme.bodySmall,
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body(context, state, students)),
        ],
      ),
    );
  }

  String _countLabel(int shown, int total) {
    final noun = total == 1 ? 'estudiante' : 'estudiantes';
    return shown == total ? '$total $noun' : '$shown de $total $noun';
  }

  Widget _body(
    BuildContext context,
    ListViewState<StudentEntity> state,
    List<StudentEntity> students,
  ) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<StudentsProvider>().refreshQuery(
            StudentsProvider.queryOf(
              page: page,
              groupId: filters.groupId,
              search: filters.search,
            ),
          ),
        );
      case ViewStatus.empty:
        return filters.groupId == null && filters.search.isEmpty
            ? AppEmptyState(
                title: 'No tienes estudiantes registrados',
                message:
                    'Importa tu lista de estudiantes desde Excel para '
                    'comenzar.',
                icon: Icons.people_alt_outlined,
                actionLabel: 'Importar estudiantes',
                onAction: () => context.push(RoutePaths.dataManagement),
              )
            : const AppEmptyState(
                title: 'Sin resultados',
                message: 'Ningún estudiante coincide con la búsqueda.',
                icon: Icons.search_off,
              );
      case ViewStatus.success:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (students.isEmpty)
              const AppEmptyState(
                title: 'Sin resultados',
                message: 'Ningún estudiante de esta página tiene ese estado.',
                icon: Icons.filter_alt_off_outlined,
              ),
            for (final student in students)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: StudentListCard(
                  student: student,
                  onTap: () =>
                      context.push(RoutePaths.studentDetail(student.id)),
                ),
              ),
            if (state.totalPages > 1)
              AppPagination(
                page: state.page,
                totalPages: state.totalPages,
                totalElements: state.totalElements,
                onPageChanged: onPageChanged,
              ),
          ],
        );
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? AppColors.accentBlue : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? AppColors.accentBlue : colors.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? Colors.white : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
