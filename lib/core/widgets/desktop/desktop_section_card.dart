import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// White section card of desktop screens: icon + title (+ subtitle)
/// header with an optional link on the right, then [child].
class DesktopSectionCard extends StatelessWidget {
  const DesktopSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.linkLabel,
    this.onLink,
    this.padding = const EdgeInsets.all(20),
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? linkLabel;
  final VoidCallback? onLink;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: colors.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: title,
                    style: textTheme.titleMedium?.copyWith(fontSize: 17),
                    children: [
                      if (subtitle != null)
                        TextSpan(
                          text: '  ·  $subtitle',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (linkLabel != null && onLink != null)
                TextButton.icon(
                  onPressed: onLink,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(linkLabel!),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentBlue,
                    textStyle: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Bordered, hoverable row/tile used inside desktop section cards.
class DesktopHoverTile extends StatefulWidget {
  const DesktopHoverTile({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  @override
  State<DesktopHoverTile> createState() => _DesktopHoverTileState();
}

class _DesktopHoverTileState extends State<DesktopHoverTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: _hovering
            ? AppColors.accentBlue.withValues(alpha: 0.04)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _hovering
                ? AppColors.accentBlue.withValues(alpha: 0.45)
                : colors.outline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}
