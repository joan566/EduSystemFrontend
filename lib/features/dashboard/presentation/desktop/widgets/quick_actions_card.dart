import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../shared/quick_actions.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';

/// The frequent tasks as a vertical list of hoverable tiles.
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DesktopSectionCard(
      icon: Icons.bolt_outlined,
      title: 'Acciones rápidas',
      child: Column(
        children: [
          for (final (i, action) in dashboardQuickActions.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            DesktopHoverTile(
              onTap: () => context.push(action.path),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  TintedIcon(icon: action.icon, color: action.color, size: 38),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      action.label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
