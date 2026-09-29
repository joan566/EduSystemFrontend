import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';

/// One of the class screen's shortcut tiles.
class ClassQuickAction {
  const ClassQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// A row of equal-width shortcut tiles (icon above a two-line label).
class ClassQuickActions extends StatelessWidget {
  const ClassQuickActions({super.key, required this.actions});

  final List<ClassQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, action) in actions.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colors.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: action.onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
                    child: Column(
                      children: [
                        TintedIcon(
                          icon: action.icon,
                          color: AppColors.accentBlue,
                          size: 44,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
