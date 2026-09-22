import 'package:flutter/material.dart';

import 'app_card.dart';

/// A single KPI card: circular tinted icon, label, big value, and a chevron
/// affordance when it navigates somewhere. Shared by any page that opens
/// with a row of at-a-glance counts (Dashboard, Teaching, ...) so the shape
/// doesn't get redefined per screen.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
    this.hasError = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  /// When true, [value] is replaced by an em dash + error icon with a
  /// tooltip — distinct from a genuine zero (§104).
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                const SizedBox(height: 2),
                if (hasError)
                  Tooltip(
                    message: 'No se pudo cargar este dato.',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('—', style: textTheme.headlineLarge),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ),
                  )
                else
                  Text(value, style: textTheme.headlineLarge),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
        ],
      ),
    );
  }
}
