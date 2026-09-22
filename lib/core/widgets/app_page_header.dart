import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Page title, optional breadcrumbs (desktop only) and actions. Compact on
/// mobile, richer on desktop (§66).
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs = const [],
    this.actions = const [],
  });

  final String title;
  final String? subtitle;

  /// Desktop-only trail, e.g. ["Estudiantes", "10-A", "Juan Pérez"].
  final List<String> breadcrumbs;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile && breadcrumbs.isNotEmpty) ...[
            _Breadcrumbs(items: breadcrumbs),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: isMobile ? textTheme.titleLarge : textTheme.headlineLarge,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ),
        ],
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(
          Icon(Icons.chevron_right, size: 14, color: style?.color),
        );
      }
      children.add(Text(items[i], style: style));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
