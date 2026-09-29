import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Top of a desktop catalog screen: title and a count/explanation line on
/// the left, actions on the right.
class DesktopCatalogHeader extends StatelessWidget {
  const DesktopCatalogHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.headlineLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          a,
        ],
      ],
    );
  }
}
