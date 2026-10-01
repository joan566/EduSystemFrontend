import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/mobile/mobile_catalog_card.dart';
import '../../../../core/widgets/mobile/mobile_catalog_header.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../../teaching/presentation/shared/class_lookup.dart';
import '../../domain/entities/academic_level_entity.dart';
import '../providers/academic_levels_provider.dart';
import '../shared/academic_level_actions.dart';
import '../shared/academic_level_form.dart';
import '../shared/level_badge.dart';
import '../shared/level_usage.dart';

/// Mobile "Grados académicos": the levels in school order, each with the
/// courses you teach in it and a shortcut to all its courses.
class AcademicLevelsMobileView extends StatelessWidget {
  const AcademicLevelsMobileView({
    super.key,
    required this.search,
    required this.onSearchChanged,
  });

  final String search;
  final ValueChanged<String> onSearchChanged;

  Future<void> _openForm(
    BuildContext context, {
    AcademicLevelEntity? initial,
  }) async {
    await showMobileForm<void>(
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

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileCatalogHeader(
            title: 'Grados académicos',
            subtitle: state.status == ViewStatus.success
                ? '${state.items.length} grados  ·  enseñas en ${usage.length}'
                : 'Los niveles del colegio',
            addTooltip: 'Nuevo grado',
            onAdd: () => _openForm(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: AppSearchField(
              hint: 'Buscar grado...',
              initialValue: search,
              onChanged: onSearchChanged,
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
                      .where(
                        (l) => matchesSearch(search, [l.name, l.description]),
                      )
                      .toList(),
                );
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    if (levels.isEmpty)
                      const AppEmptyState(
                        title: 'Sin resultados',
                        message: 'Ningún grado coincide con la búsqueda.',
                        icon: Icons.search_off,
                      ),
                    for (final level in levels)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MobileCatalogCard(
                          leading: LevelBadge(level: level),
                          title: level.name,
                          subtitle: level.description,
                          meta: Text(
                            () {
                              final courses = coursesOf(
                                usage[level.name] ?? const [],
                              );
                              return courses.isEmpty
                                  ? 'Sin cursos tuyos'
                                  : 'Tus cursos: ${courses.join(', ')}';
                            }(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          editLabel: 'Editar grado',
                          deleteLabel: 'Eliminar grado',
                          extraActions: [
                            (
                              icon: Icons.class_outlined,
                              label: 'Ver cursos de ${level.name}',
                              onTap: () => context.push(
                                RoutePaths.coursesForLevel(level.id),
                              ),
                            ),
                          ],
                          onEdit: () => _openForm(context, initial: level),
                          onDelete: () =>
                              AcademicLevelActions.delete(context, level),
                        ),
                      ),
                  ],
                );
              }(),
            },
          ),
        ],
      ),
    );
  }
}
