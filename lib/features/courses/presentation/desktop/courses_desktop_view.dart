import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/desktop/desktop_catalog_header.dart';
import '../../../../core/widgets/desktop/desktop_catalog_relations.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_list_table.dart';
import '../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../academic_levels/domain/entities/academic_level_entity.dart';
import '../../../academic_levels/presentation/providers/academic_levels_provider.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/course_entity.dart';
import '../providers/courses_provider.dart';
import '../shared/course_actions.dart';
import '../shared/course_badge.dart';
import '../shared/course_filters.dart';
import '../shared/course_form.dart';

/// Desktop "Cursos": grade and year filters over one table grouped by
/// academic year, showing what you teach in each course and its students;
/// edit and delete appear on hover.
class CoursesDesktopView extends StatelessWidget {
  const CoursesDesktopView({
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

  static const _sideWidth = 320.0;
  static const _sideBesideMinWidth = 1080.0;

  Future<void> _openForm(BuildContext context, {CourseEntity? initial}) async {
    final levels = CourseActions.levelsForForm(context);
    if (levels == null) return;
    final data = await showDesktopDialog<CourseFormResult>(
      context,
      child: CourseForm(initial: initial, levels: levels),
    );
    if (data == null || !context.mounted) return;
    await CourseActions.save(context, initial: initial, data: data);
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
    final filtered = filters.gradeId != null || filters.academicYear != null;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopCatalogHeader(
              title: 'Cursos',
              subtitle: state.status == ViewStatus.success
                  ? '${state.totalElements} cursos  ·  enseñas en ${usage.length}'
                  : 'Los grupos de cada grado, por año lectivo.',
              actions: [
                AppButton(
                  label: 'Nuevo curso',
                  icon: Icons.add,
                  onPressed: () => _openForm(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: AppDropdown<AcademicLevelEntity?>(
                    label: 'Grado',
                    value: levels
                        .where((l) => l.id == filters.gradeId)
                        .firstOrNull,
                    items: [null, ...levels],
                    itemLabel: (l) => l?.name ?? 'Todos los grados',
                    onChanged: (l) => onFiltersChanged(
                      CourseFilters(
                        gradeId: l?.id,
                        academicYear: filters.academicYear,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: AppDropdown<int?>(
                    label: 'Año lectivo',
                    value: filters.academicYear,
                    items: [
                      null,
                      ...{...filterYears(), ?filters.academicYear},
                    ],
                    itemLabel: (y) => y?.toString() ?? 'Todos los años',
                    onChanged: (y) => onFiltersChanged(
                      CourseFilters(gradeId: filters.gradeId, academicYear: y),
                    ),
                  ),
                ),
                if (filtered)
                  TextButton.icon(
                    onPressed: () => onFiltersChanged(const CourseFilters()),
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Quitar filtros'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final main = _body(context, state, usage, filtered);
                  if (constraints.maxWidth < _sideBesideMinWidth) return main;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: main),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: _sideWidth,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _YearsCard(
                                courses: courses.matching(
                                  gradeId: filters.gradeId,
                                  academicYear: filters.academicYear,
                                ),
                                usage: usage,
                              ),
                              const SizedBox(height: 16),
                              const DesktopCatalogRelations(
                                current: CatalogKind.courses,
                              ),
                            ],
                          ),
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
    BuildContext context,
    ListViewState<CourseEntity> state,
    Map<int, List<TeachingPeriodEntity>> usage,
    bool filtered,
  ) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const DesktopListTableSkeleton(
          columns: [
            SkeletonColumn('Curso', flex: 3, cell: SkeletonCell.badge),
            SkeletonColumn('Grado', flex: 2),
            SkeletonColumn('Lo que enseñas', flex: 5),
            SkeletonColumn(
              'Estudiantes',
              width: 110,
              cell: SkeletonCell.value,
              alignEnd: true,
            ),
          ],
        );
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<CoursesProvider>().refresh(),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: filtered
              ? 'Sin cursos con estos filtros'
              : 'No hay cursos registrados',
          message:
              'Un curso es un grupo de un grado en un año lectivo, como 5° A 2026.',
          icon: Icons.class_outlined,
          actionLabel: 'Nuevo curso',
          onAction: () => _openForm(context),
        );
      case ViewStatus.success:
        final textTheme = Theme.of(context).textTheme;
        final courses = [...state.items]
          ..sort((a, b) {
            final byYear = b.academicYear.compareTo(a.academicYear);
            if (byYear != 0) return byYear;
            final byGrade = a.gradeName.compareTo(b.gradeName);
            return byGrade != 0 ? byGrade : a.name.compareTo(b.name);
          });
        return DesktopListTable<CourseEntity>(
          items: courses,
          groupOf: (c) => 'Año lectivo ${c.academicYear}',
          onRowTap: (c) => _openForm(context, initial: c),
          actions: [
            DesktopRowAction(
              icon: Icons.edit_outlined,
              label: 'Editar curso',
              onTap: (c) => _openForm(context, initial: c),
            ),
            DesktopRowAction(
              icon: Icons.delete_outline,
              label: 'Eliminar curso',
              destructive: true,
              onTap: (c) => CourseActions.delete(context, c),
            ),
          ],
          columns: [
            DesktopListColumn(
              label: 'Curso',
              flex: 3,
              cell: (c) => Row(
                children: [
                  CourseBadge(course: c, size: 38),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      c.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DesktopListColumn(
              label: 'Grado',
              flex: 2,
              cell: (c) => Text(c.gradeName, style: textTheme.bodyMedium),
            ),
            DesktopListColumn(
              label: 'Lo que enseñas',
              flex: 5,
              cell: (c) {
                final subjects = subjectsOf(usage[c.id] ?? const []);
                if (subjects.isEmpty) {
                  return Text('Sin clases tuyas', style: textTheme.bodySmall);
                }
                return Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final s in subjects)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            DesktopListColumn(
              label: 'Estudiantes',
              width: 110,
              alignEnd: true,
              cell: (c) {
                final students = studentsOf(usage[c.id] ?? const []);
                return Text(
                  students?.toString() ?? '—',
                  style: textTheme.bodyMedium,
                );
              },
            ),
          ],
          footer: state.totalPages > 1
              ? AppPagination(
                  page: state.page,
                  totalPages: state.totalPages,
                  totalElements: state.totalElements,
                  onPageChanged: onPageChanged,
                )
              : null,
        );
    }
  }
}

class _YearsCard extends StatelessWidget {
  const _YearsCard({required this.courses, required this.usage});

  final List<CourseEntity> courses;
  final Map<int, List<TeachingPeriodEntity>> usage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final byYear = <int, int>{};
    for (final c in courses) {
      byYear[c.academicYear] = (byYear[c.academicYear] ?? 0) + 1;
    }
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    final peak = byYear.values.fold<int>(0, (m, v) => v > m ? v : m);
    return DesktopSectionCard(
      icon: Icons.calendar_month_outlined,
      title: 'Por año lectivo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          if (years.isEmpty) Text('Sin cursos.', style: textTheme.bodySmall),
          for (final y in years)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text('$y', style: textTheme.bodyMedium),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: peak == 0 ? 0 : byYear[y]! / peak,
                        minHeight: 8,
                        color: AppColors.accentBlue,
                        backgroundColor: AppColors.accentBlue.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${byYear[y]}',
                      textAlign: TextAlign.end,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'En esta página de resultados.',
            style: textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
