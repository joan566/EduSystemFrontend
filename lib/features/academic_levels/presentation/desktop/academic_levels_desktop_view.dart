import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/desktop/desktop_catalog_header.dart';
import '../../../../core/widgets/desktop/desktop_catalog_relations.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_list_table.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../../teaching/presentation/shared/class_lookup.dart';
import '../../domain/entities/academic_level_entity.dart';
import '../providers/academic_levels_provider.dart';
import '../shared/academic_level_actions.dart';
import '../shared/academic_level_form.dart';
import '../shared/level_badge.dart';
import '../shared/level_usage.dart';

/// Desktop "Grados académicos": the levels in school order in one table,
/// with the courses you teach in each and a jump to all its courses;
/// actions on hover and how the catalogs relate at the side.
class AcademicLevelsDesktopView extends StatelessWidget {
  const AcademicLevelsDesktopView({
    super.key,
    required this.search,
    required this.onSearchChanged,
  });

  final String search;
  final ValueChanged<String> onSearchChanged;

  static const _sideWidth = 320.0;
  static const _sideBesideMinWidth = 1080.0;

  Future<void> _openForm(
    BuildContext context, {
    AcademicLevelEntity? initial,
  }) async {
    await showDesktopDialog<void>(
      context,
      child: AcademicLevelForm(
        initial: initial,
        onSubmit: (data) =>
            AcademicLevelActions.save(context, initial: initial, data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AcademicLevelsProvider>().state;
    final usage = classesByLevel(context.watch<TeachingProvider>().allPeriods);
    final textTheme = Theme.of(context).textTheme;

    final Widget main = switch (state.status) {
      ViewStatus.initial ||
      ViewStatus.loading => const DesktopListTableSkeleton(
        columns: [
          SkeletonColumn('Grado', flex: 5, cell: SkeletonCell.badge),
          SkeletonColumn('Tus cursos', flex: 4),
          SkeletonColumn(
            'Tus clases',
            width: 100,
            cell: SkeletonCell.value,
            alignEnd: true,
          ),
        ],
      ),
      ViewStatus.error => AppErrorState(
        exception: state.error!,
        onRetry: () => context.read<AcademicLevelsProvider>().refresh(),
      ),
      ViewStatus.empty => AppEmptyState(
        title: 'No hay grados académicos',
        message:
            'Crea los niveles del colegio (por ejemplo 5° o 10°) para organizar los cursos.',
        icon: Icons.school_outlined,
        actionLabel: 'Nuevo grado',
        onAction: () => _openForm(context),
      ),
      ViewStatus.success => () {
        final levels = sortLevels(
          state.items
              .where((l) => matchesSearch(search, [l.name, l.description]))
              .toList(),
        );
        if (levels.isEmpty) {
          return const AppEmptyState(
            title: 'Sin resultados',
            message: 'Ningún grado coincide con la búsqueda.',
            icon: Icons.search_off,
          );
        }
        return DesktopListTable<AcademicLevelEntity>(
          items: levels,
          onRowTap: (l) => _openForm(context, initial: l),
          actions: [
            DesktopRowAction(
              icon: Icons.class_outlined,
              label: 'Ver cursos',
              onTap: (l) => context.go(RoutePaths.coursesForLevel(l.id)),
            ),
            DesktopRowAction(
              icon: Icons.edit_outlined,
              label: 'Editar grado',
              onTap: (l) => _openForm(context, initial: l),
            ),
            DesktopRowAction(
              icon: Icons.delete_outline,
              label: 'Eliminar grado',
              destructive: true,
              onTap: (l) => AcademicLevelActions.delete(context, l),
            ),
          ],
          columns: [
            DesktopListColumn(
              label: 'Grado',
              flex: 5,
              cell: (l) {
                final description = l.description?.trim();
                return Row(
                  children: [
                    LevelBadge(level: l, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.name,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (description != null && description.isNotEmpty)
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            DesktopListColumn(
              label: 'Tus cursos',
              flex: 4,
              cell: (l) {
                final courses = coursesOf(usage[l.name] ?? const []);
                if (courses.isEmpty) {
                  return Text('—', style: textTheme.bodySmall);
                }
                return Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final c in courses)
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
                          c,
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
              label: 'Tus clases',
              width: 100,
              alignEnd: true,
              cell: (l) => Text(
                '${usage[l.name]?.length ?? 0}',
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        );
      }(),
    };

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopCatalogHeader(
              title: 'Grados académicos',
              subtitle: state.status == ViewStatus.success
                  ? '${state.items.length} grados  ·  enseñas en ${usage.length}'
                  : 'Los niveles del colegio.',
              actions: [
                AppButton(
                  label: 'Nuevo grado',
                  icon: Icons.add,
                  onPressed: () => _openForm(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 360,
                child: AppSearchField(
                  hint: 'Buscar grado...',
                  initialValue: search,
                  onChanged: onSearchChanged,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < _sideBesideMinWidth) return main;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: main),
                      const SizedBox(width: 24),
                      const SizedBox(
                        width: _sideWidth,
                        child: SingleChildScrollView(
                          child: DesktopCatalogRelations(
                            current: CatalogKind.levels,
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
}
