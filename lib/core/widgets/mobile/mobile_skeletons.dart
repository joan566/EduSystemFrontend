import 'package:flutter/material.dart';

import '../shared/skeleton/skeleton.dart';
import '../shared/skeleton/skeleton_blocks.dart';

/// Placeholder of a mobile card listing (`MobileCardList`, catalog cards):
/// bordered cards with a leading avatar/badge, title, subtitle and an
/// optional trailing chip.
///
/// Fills a page body by default; with [shrinkWrap] it is a plain column
/// for use inside a scroll view (a tab, a section).
class MobileListSkeleton extends StatelessWidget {
  const MobileListSkeleton({
    super.key,
    this.itemCount = 7,
    this.leading = SkeletonLeading.circle,
    this.leadingSize = 44,
    this.trailingWidth,
    this.trailingHeight = 22,
    this.meta = false,
    this.bar = false,
    this.radius = 14,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 24),
    this.shrinkWrap = false,
  });

  final int itemCount;
  final SkeletonLeading leading;
  final double leadingSize;

  /// Width of a trailing chip/value on each card; none when null.
  final double? trailingWidth;
  final double trailingHeight;

  /// Adds a third, short line (counts, dates) under the subtitle.
  final bool meta;

  /// Adds a full-width progress bar under the row (grades, progress).
  final bool bar;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final list = Padding(
      padding: padding,
      child: SkeletonRepeat(
        count: itemCount,
        builder: (context, i) => SkeletonSurface(
          radius: radius,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonTile(
                leading: leading,
                leadingSize: leadingSize,
                titleFactor: SkeletonRepeat.factor(i),
                subtitleFactor: SkeletonRepeat.factor(i + 2, base: 0.75),
                trailingWidth: trailingWidth,
                trailingHeight: trailingHeight,
              ),
              if (meta)
                Padding(
                  padding: EdgeInsets.only(
                    top: 6,
                    left: leading == SkeletonLeading.none
                        ? 0
                        : leadingSize + 12,
                  ),
                  child: SkeletonText(
                    style: textTheme.bodySmall,
                    widthFactor: SkeletonRepeat.factor(i + 1, base: 0.45),
                  ),
                ),
              if (bar) ...[
                const SizedBox(height: 12),
                const SkeletonBox(height: 6, radius: 3),
              ],
            ],
          ),
        ),
      ),
    );
    return Skeleton(child: shrinkWrap ? list : SkeletonFill(child: list));
  }
}

/// Placeholder of a `MobileSectionCard`: the icon + title header and
/// [rows] tile rows (or a custom [child]).
///
/// It is not a [Skeleton] root, so several can share one shimmer inside a
/// page-level skeleton; wrap it in [Skeleton] when used alone.
class MobileSectionSkeleton extends StatelessWidget {
  const MobileSectionSkeleton({
    super.key,
    this.rows = 3,
    this.leading = SkeletonLeading.square,
    this.leadingSize = 40,
    this.trailingWidth,
    this.child,
  });

  final int rows;
  final SkeletonLeading leading;
  final double leadingSize;
  final double? trailingWidth;

  /// Replaces the default rows.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SkeletonSurface(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 20, height: 20, radius: 6),
              const SizedBox(width: 10),
              SkeletonText(style: textTheme.titleMedium, width: 120),
            ],
          ),
          const SizedBox(height: 14),
          child ??
              SkeletonRepeat(
                count: rows,
                spacing: 14,
                builder: (context, i) => SkeletonTile(
                  leading: leading,
                  leadingSize: leadingSize,
                  titleFactor: SkeletonRepeat.factor(i),
                  subtitleFactor: SkeletonRepeat.factor(i + 3, base: 0.7),
                  trailingWidth: trailingWidth,
                ),
              ),
        ],
      ),
    );
  }
}

/// Placeholder of a mobile detail screen body: a hero (avatar, name and
/// subtitle), optional [tabs] strip and [stats] tiles, then [sections]
/// section cards.
class MobileDetailSkeleton extends StatelessWidget {
  const MobileDetailSkeleton({
    super.key,
    this.avatar = SkeletonLeading.circle,
    this.tabs = 0,
    this.stats = 0,
    this.sections = 2,
    this.rowsPerSection = 3,
  });

  final SkeletonLeading avatar;
  final int tabs;
  final int stats;
  final int sections;
  final int rowsPerSection;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final outline = Theme.of(context).colorScheme.outline;

    return Skeleton(
      child: SkeletonFill(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
              child: SkeletonTile(
                leading: avatar,
                leadingSize: 64,
                gap: 16,
                titleStyle: textTheme.titleLarge,
                titleFactor: 0.6,
                subtitleFactor: 0.8,
              ),
            ),
            if (tabs > 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: outline)),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < tabs; i++)
                      const Expanded(
                        child: Center(child: SkeletonBox(width: 72)),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (stats > 0) ...[
                    Row(
                      children: [
                        for (var i = 0; i < stats; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          const Expanded(child: MobileStatSkeleton()),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  SkeletonRepeat(
                    count: sections,
                    spacing: 14,
                    builder: (context, i) =>
                        MobileSectionSkeleton(rows: rowsPerSection),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder of a small mobile stat tile: a value over its label.
class MobileStatSkeleton extends StatelessWidget {
  const MobileStatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SkeletonSurface(
      radius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonText(style: textTheme.titleLarge, width: 40),
          const SizedBox(height: 4),
          SkeletonText(style: textTheme.bodySmall, width: 64),
        ],
      ),
    );
  }
}
