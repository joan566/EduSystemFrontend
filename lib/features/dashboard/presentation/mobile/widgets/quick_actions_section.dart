import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../shared/quick_actions.dart';
import '../../../../../core/widgets/mobile/mobile_section_card.dart';

/// 2×2 grid of the teacher's most frequent tasks. Each one opens the
/// screen where that task starts (picking the class happens there).
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return MobileSectionCard(
      icon: Icons.bolt_outlined,
      title: 'Acciones rápidas',
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        children: [
          for (var row = 0; row < dashboardQuickActions.length; row += 2) ...[
            if (row > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _QuickActionTile(action: dashboardQuickActions[row]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionTile(
                      action: dashboardQuickActions[row + 1],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final DashboardQuickAction action;

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
