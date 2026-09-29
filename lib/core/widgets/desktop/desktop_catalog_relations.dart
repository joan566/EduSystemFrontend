import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/route_paths.dart';
import '../../theme/app_colors.dart';
import 'desktop_section_card.dart';

enum CatalogKind { levels, courses, subjects, periods }

/// Side-panel card that explains where a catalog fits: a grado groups
/// cursos; a clase is a materia taught to a curso during a periodo. The
/// current catalog is highlighted; the others link to their screens.
class DesktopCatalogRelations extends StatelessWidget {
  const DesktopCatalogRelations({super.key, required this.current});

  final CatalogKind current;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget node(
      CatalogKind kind,
      IconData icon,
      String label,
      String detail,
      String path,
    ) {
      final active = kind == current;
      return Material(
        color: active
            ? AppColors.accentBlue.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: active ? null : () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active
                      ? AppColors.accentBlue
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: active ? AppColors.accentBlue : null,
                        ),
                      ),
                      Text(
                        detail,
                        style: textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (!active)
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget arrow(String text) => Padding(
      padding: const EdgeInsets.only(left: 19),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 18,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 14),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );

    return DesktopSectionCard(
      icon: Icons.account_tree_outlined,
      title: 'Cómo se relacionan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          node(
            CatalogKind.levels,
            Icons.school_outlined,
            'Grados académicos',
            'Niveles como 5° o 10°',
            RoutePaths.academicLevels,
          ),
          arrow('agrupa'),
          node(
            CatalogKind.courses,
            Icons.class_outlined,
            'Cursos',
            'Un grupo de un grado en un año: 5° A',
            RoutePaths.courses,
          ),
          arrow('recibe'),
          node(
            CatalogKind.subjects,
            Icons.menu_book_outlined,
            'Materias',
            'Lo que se enseña: Castellano',
            RoutePaths.subjects,
          ),
          arrow('durante'),
          node(
            CatalogKind.periods,
            Icons.calendar_month_outlined,
            'Periodos académicos',
            'Los cortes del año lectivo',
            RoutePaths.periods,
          ),
          const SizedBox(height: 8),
          Text(
            'Una clase une una materia con un curso en un periodo.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
