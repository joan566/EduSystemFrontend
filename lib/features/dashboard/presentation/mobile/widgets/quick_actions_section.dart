import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import 'mobile_dashboard_section.dart';

/// 2×2 grid of the teacher's most frequent tasks. Each one opens the
/// screen where that task starts (picking the class happens there).
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const actions = [
      _QuickAction(
        label: 'Crear examen',
        icon: Icons.description_outlined,
        color: AppColors.accentBlue,
        path: RoutePaths.exams,
      ),
      _QuickAction(
        label: 'Importar estudiantes',
        icon: Icons.person_add_alt_1_outlined,
        color: AppColors.accentGreen,
        path: RoutePaths.dataManagement,
      ),
      _QuickAction(
        label: 'Nueva actividad',
        icon: Icons.assignment_add,
        color: AppColors.accentPurple,
        path: RoutePaths.activities,
      ),
      _QuickAction(
        label: 'Tomar asistencia',
        icon: Icons.event_available_outlined,
        color: AppColors.accentTeal,
        path: RoutePaths.attendance,
      ),
    ];

    return MobileDashboardSection(
      icon: Icons.bolt_outlined,
      title: 'Acciones rápidas',
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        children: [
          for (var row = 0; row < actions.length; row += 2) ...[
            if (row > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _QuickActionTile(action: actions[row])),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickActionTile(action: actions[row + 1])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.path,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String path;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(action.path),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 4, 10),
          child: Row(
            children: [
              TintedIcon(icon: action.icon, color: action.color, size: 34),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
