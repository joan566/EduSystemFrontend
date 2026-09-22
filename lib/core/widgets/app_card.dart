import 'package:flutter/material.dart';

/// Themed content card with standard padding.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Card(child: Padding(padding: padding, child: child));
    }
    return _InteractiveAppCard(padding: padding, onTap: onTap!, child: child);
  }
}

/// A card whose border brightens on hover (desktop/web) — a Stripe/Vercel-
/// style cue that it's interactive, on top of InkWell's ripple, which alone
/// was easy to miss on a flat 1px-border card.
class _InteractiveAppCard extends StatefulWidget {
  const _InteractiveAppCard({
    required this.child,
    required this.padding,
    required this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;

  @override
  State<_InteractiveAppCard> createState() => _InteractiveAppCardState();
}

class _InteractiveAppCardState extends State<_InteractiveAppCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: _hovering
                ? colors.primary.withValues(alpha: 0.55)
                : colors.outline,
            width: _hovering ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}
