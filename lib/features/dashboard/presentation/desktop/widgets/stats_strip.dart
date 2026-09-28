import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../courses/presentation/providers/courses_provider.dart';
import '../../../../students/presentation/providers/students_provider.dart';
import '../../../../teaching/presentation/providers/teaching_provider.dart';

/// One card, three at-a-glance counts separated by dividers.
class StatsStrip extends StatelessWidget {
  const StatsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentsProvider>().state;
    final courses = context.watch<CoursesProvider>().state;
    final assignments = context.watch<TeachingProvider>().assignmentsState;
    final colors = Theme.of(context).colorScheme;

    final items = [
      _Stat(
        label: 'Estudiantes',
        state: students,
        icon: Icons.people_alt_outlined,
        color: AppColors.accentBlue,
        path: RoutePaths.students,
      ),
      _Stat(
        label: 'Cursos',
        state: courses,
        icon: Icons.menu_book_outlined,
        color: AppColors.accentBlue,
        path: RoutePaths.courses,
      ),
      _Stat(
        label: 'Clases activas',
        state: assignments,
        icon: Icons.groups_outlined,
        color: AppColors.accentGreen,
        path: RoutePaths.teaching,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in items.indexed) ...[
              if (i > 0) VerticalDivider(width: 1, color: colors.outline),
              Expanded(child: item),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.state,
    required this.icon,
    required this.color,
    required this.path,
  });

  final String label;
  final ListViewState<dynamic> state;
  final IconData icon;
  final Color color;
  final String path;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final hasError = state.status == ViewStatus.error;

    return InkWell(
      onTap: () => context.go(path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasError)
                    Tooltip(
                      message: 'No se pudo cargar este dato.',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('—', style: textTheme.headlineLarge),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: colors.error,
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '${state.totalElements}',
                      style: textTheme.headlineLarge,
                    ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colors.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
