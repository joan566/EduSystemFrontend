import 'package:flutter/material.dart';

import 'skeleton.dart';

/// The chrome of a card around bones: the real card's surface, radius and
/// border stay solid while only its content shimmers, so the placeholder
/// reads as the empty version of that card.
class SkeletonSurface extends StatelessWidget {
  const SkeletonSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Defaults to the theme's surface.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
      ),
      child: child,
    );
  }
}

/// Leading shape of a [SkeletonTile].
enum SkeletonLeading { none, circle, square }

/// A row placeholder: an optional leading avatar/icon, a title and
/// subtitle line, and an optional trailing bone (value, chip, chevron).
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({
    super.key,
    this.leading = SkeletonLeading.circle,
    this.leadingSize = 40,
    this.titleFactor = 0.55,
    this.subtitleFactor = 0.8,
    this.subtitle = true,
    this.trailingWidth,
    this.trailingHeight = 14,
    this.titleStyle,
    this.subtitleStyle,
    this.gap = 12,
  });

  final SkeletonLeading leading;
  final double leadingSize;
  final double titleFactor;
  final double subtitleFactor;
  final bool subtitle;

  /// Width of a trailing bone (a value or status chip); none when null.
  final double? trailingWidth;
  final double trailingHeight;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        switch (leading) {
          SkeletonLeading.none => const SizedBox.shrink(),
          SkeletonLeading.circle => SkeletonCircle(size: leadingSize),
          SkeletonLeading.square => SkeletonBox(
            width: leadingSize,
            height: leadingSize,
            radius: leadingSize * 0.28,
          ),
        },
        if (leading != SkeletonLeading.none) SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonText(
                style: titleStyle ?? textTheme.titleSmall,
                widthFactor: titleFactor,
              ),
              if (subtitle) ...[
                const SizedBox(height: 4),
                SkeletonText(
                  style: subtitleStyle ?? textTheme.bodySmall,
                  widthFactor: subtitleFactor,
                ),
              ],
            ],
          ),
        ),
        if (trailingWidth != null) ...[
          SizedBox(width: gap),
          SkeletonBox(
            width: trailingWidth,
            height: trailingHeight,
            radius: trailingHeight / 2,
          ),
        ],
      ],
    );
  }
}

/// [count] copies of [builder] separated by [spacing], each one slightly
/// different (via its index) so a list placeholder doesn't look stamped.
class SkeletonRepeat extends StatelessWidget {
  const SkeletonRepeat({
    super.key,
    required this.count,
    required this.builder,
    this.spacing = 10,
    this.separator,
  });

  final int count;
  final Widget Function(BuildContext context, int index) builder;
  final double spacing;

  /// Drawn between items instead of the [spacing] gap (e.g. a divider).
  final Widget? separator;

  /// A width factor near [base] that varies from row to row ([index]).
  static double factor(int index, {double base = 0.55}) =>
      (base + const [0, 0.14, -0.1, 0.2, -0.04, 0.08][index % 6]).clamp(
        0.3,
        0.9,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) separator ?? SizedBox(height: spacing),
          builder(context, i),
        ],
      ],
    );
  }
}

/// Fills a bounded area (a page body) with [child] without scrolling or
/// overflowing: whatever doesn't fit is clipped, as a skeleton only has to
/// cover the visible part of the screen.
class SkeletonFill extends StatelessWidget {
  const SkeletonFill({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      child: child,
    );
  }
}

/// A standalone list of [count] [SkeletonTile]s (its own [Skeleton] root):
/// the placeholder of rows inside a card or section whose data is loading.
class SkeletonTileList extends StatelessWidget {
  const SkeletonTileList({
    super.key,
    this.count = 3,
    this.leading = SkeletonLeading.square,
    this.leadingSize = 40,
    this.trailingWidth,
    this.trailingHeight = 14,
    this.subtitle = true,
    this.spacing = 14,
    this.padding = EdgeInsets.zero,
  });

  final int count;
  final SkeletonLeading leading;
  final double leadingSize;
  final double? trailingWidth;
  final double trailingHeight;
  final bool subtitle;
  final double spacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Padding(
        padding: padding,
        child: SkeletonRepeat(
          count: count,
          spacing: spacing,
          builder: (context, i) => SkeletonTile(
            leading: leading,
            leadingSize: leadingSize,
            subtitle: subtitle,
            titleFactor: SkeletonRepeat.factor(i),
            subtitleFactor: SkeletonRepeat.factor(i + 3, base: 0.7),
            trailingWidth: trailingWidth,
            trailingHeight: trailingHeight,
          ),
        ),
      ),
    );
  }
}

/// A progress ring with its headline figure and caption, plus a row of
/// [stats] small figures below: the placeholder of a class progress card.
/// Not a [Skeleton] root.
class SkeletonRingSummary extends StatelessWidget {
  const SkeletonRingSummary({super.key, this.ringSize = 92, this.stats = 3});

  final double ringSize;
  final int stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SkeletonCircle(size: ringSize),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(
                    style: textTheme.headlineLarge?.copyWith(fontSize: 24),
                    width: 80,
                  ),
                  const SizedBox(height: 4),
                  SkeletonText(style: textTheme.bodySmall, width: 120),
                ],
              ),
            ),
          ],
        ),
        if (stats > 0) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < stats; i++)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(style: textTheme.titleLarge, width: 28),
                      const SizedBox(height: 2),
                      SkeletonText(style: textTheme.bodySmall, width: 60),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A standalone list of "label ........ value" lines (its own [Skeleton]
/// root): the placeholder of compact facts or per-item grades in a panel.
class SkeletonValueRows extends StatelessWidget {
  const SkeletonValueRows({super.key, this.count = 3, this.valueWidth = 32});

  final int count;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Skeleton(
      child: SkeletonRepeat(
        count: count,
        spacing: 0,
        builder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: SkeletonText(
                  style: textTheme.bodyMedium,
                  widthFactor: SkeletonRepeat.factor(i, base: 0.7),
                ),
              ),
              const SizedBox(width: 12),
              SkeletonText(style: textTheme.titleSmall, width: valueWidth),
            ],
          ),
        ),
      ),
    );
  }
}
