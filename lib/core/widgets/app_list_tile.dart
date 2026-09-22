import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Polished list-item card for mobile list views (§66's `mobileCardBuilder`
/// slot): an icon in a tinted container, title/subtitle, and an optional
/// trailing widget (chip, icon button, chevron). Replaces the old bare
/// `Card(child: ListTile(...))` pattern so every feature's mobile list
/// shares the same visual weight as the rest of the redesigned app.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleMaxLines = 1,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.background,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final int subtitleMaxLines;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  /// Optional whole-card tint (e.g. a warning wash for "needs review" rows).
  /// Leave null for the default surface color.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;

    return Card(
      color: background,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: subtitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
