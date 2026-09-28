import 'package:flutter/material.dart';

/// Desktop page header: optional breadcrumbs, large title, subtitle and
/// right-aligned actions (§66).
class DesktopPageHeader extends StatelessWidget {
  const DesktopPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs = const [],
    this.actions = const [],
    this.onBack,
  });

  final String title;
  final String? subtitle;

  /// Trail such as ["Estudiantes", "10-A", "Juan Pérez"].
  final List<String> breadcrumbs;
  final List<Widget> actions;

  /// Shows a back arrow before the title (detail pages pushed on top of a
  /// list).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breadcrumbs.isNotEmpty) ...[
            _Breadcrumbs(items: breadcrumbs),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (onBack != null) ...[
                IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.headlineLarge),
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
        children.add(Icon(Icons.chevron_right, size: 14, color: style?.color));
      }
      children.add(Text(items[i], style: style));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
