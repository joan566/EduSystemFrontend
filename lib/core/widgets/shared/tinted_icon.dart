import 'package:flutter/material.dart';

/// Tinted rounded square behind an icon — the recurring "colored
/// badge" motif (subjects, quick actions, activity).
class TintedIcon extends StatelessWidget {
  const TintedIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.solid = false,
    this.circle = false,
  });

  final IconData icon;
  final Color color;
  final double size;

  /// Solid fill with a white glyph, instead of a light tint.
  final bool solid;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.12),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: size * 0.5, color: solid ? Colors.white : color),
    );
  }
}
