import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/mobile/mobile_catalog_card.dart';
import '../../../../core/widgets/mobile/mobile_catalog_header.dart';
import '../../../../core/widgets/mobile/mobile_filter_pills.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_select_field.dart';
import '../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../academic_levels/domain/entities/academic_level_entity.dart';
import '../../../academic_levels/presentation/providers/academic_levels_provider.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/course_entity.dart';
import '../providers/courses_provider.dart';
import '../shared/course_actions.dart';
import '../shared/course_badge.dart';
import '../shared/course_filters.dart';
import '../shared/course_form.dart';

/// Mobile "Cursos": grade picker and year pills, then one card per course
/// with the subjects you teach there and its students.
class CoursesMobileView extends StatelessWidget {
  const CoursesMobileView({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.page,
    required this.onPageChanged,
  });

  final CourseFilters filters;
  final ValueChanged<CourseFilters> onFiltersChanged;

  /// Page of the filtered courses (owned by the page entry point).
  final int page;
  final ValueChanged<int> onPageChanged;

  Future<void> _openForm(BuildContext context, {CourseEntity? initial}) async {
    final levels = CourseActions.levelsForForm(context);
    if (levels == null) return;
    await showMobileForm<void>(
      context,
      child: CourseForm(
        initial: initial,
        levels: levels,
        onSubmit: (data) =>
            CourseActions.save(context, initial: initial, data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CoursesProvider>();
    final state = courses.query(
      gradeId: filters.gradeId,
      academicYear: filters.academicYear,
      page: page,
    );
    final levels = context.watch<AcademicLevelsProvider>().all;
    final usage = classesByCourse(context.watch<TeachingProvider>().allPeriods);
    final level = levels.where((l) => l.id == filters.gradeId).firstOrNull;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileCatalogHeader(
            title: 'Cursos',
            subtitle: state.status == ViewStatus.success
                ? '${state.totalElements} cursos${level == null ? '' : ' de ${level.name}'}'
                : 'Los grupos de cada grado',
            addTooltip: 'Nuevo curso',
            onAdd: () => _openForm(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: MobileSelectField<AcademicLevelEntity?>(
              icon: Icons.school_outlined,
              label: 'Grado',
              value: level,
              options: [null, ...levels],
              itemLabel: (l) => l?.name ?? 'Todos los grados',
              onChanged: (l) => onFiltersChanged(
                CourseFilters(
                  gradeId: l?.id,
                  academicYear: filters.academicYear,
                ),
              ),
            ),
          ),
          MobileFilterPills<int?>(
            options: [null, ...filterYears()],
            selected: filters.academicYear,
            label: (y) => y?.toString() ?? 'Todos los años',
            onSelected: (y) => onFiltersChanged(
              CourseFilters(gradeId: filters.gradeId, academicYear: y),
            ),
          ),
          Expanded(
            child: switch (state.status) {
              ViewStatus.initial ||
              ViewStatus.loading => const MobileListSkeleton(
                leading: SkeletonLeading.square,
                leadingSize: 48,
                meta: true,
              ),
              ViewStatus.error => AppErrorState(
                exception: state.error!,
                onRetry: () => context.read<CoursesProvider>().refresh(),
              ),
              ViewStatus.empty => AppEmptyState(
                title: filters.gradeId == null && filters.academicYear == null
                    ? 'No hay cursos registrados'
                    : 'Sin cursos con estos filtros',
                message:
                    'Un curso es un grupo de un grado en un año lectivo, como 5° A 2026.',
                icon: Icons.class_outlined,
                actionLabel: 'Nuevo curso',
                onAction: () => _openForm(context),
              ),
              ViewStatus.success => ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  for (final course in state.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MobileCatalogCard(
                        leading: CourseBadge(course: course),
                        title: course.displayName,
                        subtitle: 'Año lectivo ${course.academicYear}',
                        meta: Text(
                          () {
                            final classes = usage[course.id] ?? const [];
                            if (classes.isEmpty) return 'Sin clases tuyas';
                            final students = studentsOf(classes);
                            return [
                              subjectsOf(classes).join(', '),
                              if (students != null) '$students estudiantes',
                            ].join('  ·  ');
                          }(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        editLabel: 'Editar curso',
                        deleteLabel: 'Eliminar curso',
                        onEdit: () => _openForm(context, initial: course),
                        onDelete: () => CourseActions.delete(context, course),
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
              ),
            },
          ),
        ],
      ),
    );
  }
}
