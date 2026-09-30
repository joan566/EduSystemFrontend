import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../shared/skeleton/skeleton.dart';
import '../shared/skeleton/skeleton_blocks.dart';

/// What a [DesktopListTableSkeleton] column's cells look like.
enum SkeletonCell {
  /// A single text line.
  text,

  /// Round avatar + title and subtitle (a person).
  entity,

  /// Rounded-square badge/icon + title and subtitle (a catalog item).
  badge,

  /// A rounded status chip.
  chip,

  /// A short number/value (right aligned when the column is).
  value,

  /// A thin progress bar.
  bar,

  /// A row of segmented-button options (e.g. attendance states).
  segments,
}

/// A column of a [DesktopListTableSkeleton]. The header keeps the real
/// [label] so the placeholder already reads as the table it will become.
class SkeletonColumn {
  const SkeletonColumn(
    this.label, {
    this.flex = 1,
    this.width,
    this.cell = SkeletonCell.text,
    this.alignEnd = false,
  });

  final String label;
  final int flex;
  final double? width;
  final SkeletonCell cell;
  final bool alignEnd;
}

/// Placeholder of a `DesktopListTable`: same card, same uppercase header
/// (with the real column labels) and [rows] rows of bones shaped like each
/// column's content.
class DesktopListTableSkeleton extends StatelessWidget {
  const DesktopListTableSkeleton({
    super.key,
    required this.columns,
    this.rows = 8,
    this.shrinkWrap = false,
    this.root = true,
  });

  final List<SkeletonColumn> columns;
  final int rows;

  /// A plain column (inside a scroll view) instead of filling the height.
  final bool shrinkWrap;

  /// Whether this is its own [Skeleton] root; false when it sits inside a
  /// larger skeleton that already provides the shimmer.
  final bool root;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final header = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(letterSpacing: 0.4);

    Widget sized(SkeletonColumn c, Widget child) => c.width != null
        ? SizedBox(width: c.width, child: child)
        : Expanded(flex: c.flex, child: child);

    final body = SkeletonRepeat(
      count: rows,
      separator: Divider(height: 1, color: colors.outline),
      builder: (context, i) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
        child: Row(
          children: [
            for (final (j, c) in columns.indexed)
              sized(
                c,
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _cell(context, c, i + j),
                ),
              ),
          ],
        ),
      ),
    );

    final table = Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              children: [
                for (final c in columns)
                  sized(
                    c,
                    Text(
                      c.label.toUpperCase(),
                      textAlign: c.alignEnd ? TextAlign.end : TextAlign.start,
                      style: header,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outline),
          if (shrinkWrap) body else Expanded(child: SkeletonFill(child: body)),
        ],
      ),
    );
    return root ? Skeleton(child: table) : table;
  }

  Widget _cell(BuildContext context, SkeletonColumn c, int i) {
    final textTheme = Theme.of(context).textTheme;
    final align = c.alignEnd
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    return switch (c.cell) {
      SkeletonCell.entity || SkeletonCell.badge => SkeletonTile(
        leading: c.cell == SkeletonCell.entity
            ? SkeletonLeading.circle
            : SkeletonLeading.square,
        leadingSize: c.cell == SkeletonCell.entity ? 36 : 40,
        titleFactor: SkeletonRepeat.factor(i, base: 0.6),
        subtitleFactor: SkeletonRepeat.factor(i + 3, base: 0.45),
      ),
      SkeletonCell.chip => Align(
        alignment: align,
        child: const SkeletonBox(width: 74, height: 22, radius: 11),
      ),
      SkeletonCell.value => Align(
        alignment: align,
        child: SkeletonText(style: textTheme.titleSmall, width: 36),
      ),
      SkeletonCell.bar => const SkeletonBox(height: 6, radius: 3),
      SkeletonCell.segments => Row(
        children: [
          for (var k = 0; k < 4; k++) ...[
            if (k > 0) const SizedBox(width: 6),
            const Expanded(child: SkeletonBox(height: 30, radius: 8)),
          ],
        ],
      ),
      SkeletonCell.text => SkeletonText(
        widthFactor: SkeletonRepeat.factor(i, base: 0.65),
      ),
    };
  }
}

/// Placeholder of a `DesktopSectionCard`: icon + title header and [rows]
/// tile rows (or a custom [child]). Not a [Skeleton] root.
class DesktopSectionSkeleton extends StatelessWidget {
  const DesktopSectionSkeleton({
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 22, height: 22, radius: 6),
              const SizedBox(width: 12),
              SkeletonText(
                style: textTheme.titleMedium?.copyWith(fontSize: 17),
                width: 150,
              ),
            ],
          ),
          const SizedBox(height: 18),
          child ??
              SkeletonRepeat(
                count: rows,
                spacing: 16,
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

/// Placeholder of a `DesktopStatCard`: round icon, label and big value.
/// Not a [Skeleton] root.
class DesktopStatCardSkeleton extends StatelessWidget {
  const DesktopStatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SkeletonSurface(
      radius: 10,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const SkeletonCircle(size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(style: textTheme.bodySmall, width: 90),
                const SizedBox(height: 2),
                SkeletonText(style: textTheme.headlineLarge, width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of [count] stat card placeholders. Not a [Skeleton] root.
class DesktopStatsRowSkeleton extends StatelessWidget {
  const DesktopStatsRowSkeleton({super.key, this.count = 4, this.gap = 16});

  final int count;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(width: gap),
          const Expanded(child: DesktopStatCardSkeleton()),
        ],
      ],
    );
  }
}

/// Placeholder of a desktop page header: title and subtitle on the left,
/// optional action buttons on the right, with an optional leading avatar
/// (detail pages). Not a [Skeleton] root.
class DesktopHeaderSkeleton extends StatelessWidget {
  const DesktopHeaderSkeleton({
    super.key,
    this.avatar = SkeletonLeading.none,
    this.actions = 1,
  });

  final SkeletonLeading avatar;
  final int actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: SkeletonTile(
            leading: avatar,
            leadingSize: 64,
            gap: 18,
            titleStyle: textTheme.headlineMedium,
            titleFactor: 0.4,
            subtitleStyle: textTheme.bodyMedium,
            subtitleFactor: 0.55,
          ),
        ),
        for (var i = 0; i < actions; i++) ...[
          const SizedBox(width: 12),
          const SkeletonBox(width: 120, height: 40, radius: 8),
        ],
      ],
    );
  }
}

/// Placeholder of a desktop detail page: header, optional [stats] row and
/// [tabs] strip, a side [rail] of cards (when it fits) and the [main]
/// content (section cards by default).
class DesktopDetailSkeleton extends StatelessWidget {
  const DesktopDetailSkeleton({
    super.key,
    this.avatar = SkeletonLeading.circle,
    this.actions = 1,
    this.stats = 0,
    this.tabs = 0,
    this.rail = 0,
    this.railWidth = 340,
    this.railEnd = false,
    this.main,
    this.sections = 2,
  });

  final SkeletonLeading avatar;
  final int actions;
  final int stats;
  final int tabs;

  /// Number of cards in the side column; none when 0.
  final int rail;
  final double railWidth;

  /// Puts the side column after the main content instead of before it.
  final bool railEnd;

  /// Main content; [sections] section cards when null.
  final Widget? main;
  final int sections;

  static const _railBesideMinWidth = 1100.0;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tabs > 0) ...[
          Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: outline)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < tabs; i++) ...[
                  if (i > 0) const SizedBox(width: 28),
                  SkeletonBox(width: 70.0 + 24 * (i % 2), height: 14),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        main ??
            SkeletonRepeat(
              count: sections,
              spacing: 20,
              builder: (context, i) => DesktopSectionSkeleton(rows: 3 + i % 2),
            ),
      ],
    );

    return Skeleton(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final railBeside =
              rail > 0 && constraints.maxWidth >= _railBesideMinWidth;
          final railCards = SkeletonRepeat(
            count: rail,
            spacing: 16,
            builder: (context, i) => DesktopSectionSkeleton(rows: 2 + i % 2),
          );
          return SkeletonFill(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DesktopHeaderSkeleton(avatar: avatar, actions: actions),
                const SizedBox(height: 24),
                if (stats > 0) ...[
                  DesktopStatsRowSkeleton(count: stats),
                  const SizedBox(height: 20),
                ],
                if (railBeside)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!railEnd) ...[
                        SizedBox(width: railWidth, child: railCards),
                        const SizedBox(width: 24),
                      ],
                      Expanded(child: content),
                      if (railEnd) ...[
                        const SizedBox(width: 20),
                        SizedBox(width: railWidth, child: railCards),
                      ],
                    ],
                  )
                else ...[
                  if (rail > 0) ...[railCards, const SizedBox(height: 20)],
                  content,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Placeholder of a `DesktopDataTable`: the same card and heading row
/// (with the real column labels) over [rows] rows of bones.
class DesktopDataTableSkeleton extends StatelessWidget {
  const DesktopDataTableSkeleton({
    super.key,
    required this.columns,
    this.rows = 8,
  });

  final List<SkeletonColumn> columns;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tableTheme = theme.dataTableTheme;
    final headingStyle =
        tableTheme.headingTextStyle ?? theme.textTheme.titleSmall;

    Widget row(List<Widget> cells) => Row(
      children: [
        for (final (i, c) in columns.indexed)
          c.width != null
              ? SizedBox(width: c.width, child: cells[i])
              : Expanded(flex: c.flex, child: cells[i]),
      ],
    );

    return Skeleton(
      child: SkeletonFill(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: SkeletonSurface(
          radius: 10,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: tableTheme.headingRowHeight ?? 56,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.centerLeft,
                color: tableTheme.headingRowColor?.resolve({}),
                child: row([
                  for (final c in columns)
                    Text(
                      c.label,
                      style: headingStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ]),
              ),
              SkeletonRepeat(
                count: rows,
                separator: Divider(height: 1, color: colors.outline),
                builder: (context, i) => Container(
                  height: tableTheme.dataRowMinHeight ?? 48,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.centerLeft,
                  child: row([
                    for (final (j, c) in columns.indexed)
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: c.cell == SkeletonCell.value
                            ? const Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: SkeletonBox(width: 56, height: 12),
                              )
                            : SkeletonText(
                                widthFactor: SkeletonRepeat.factor(
                                  i + j,
                                  base: 0.6,
                                ),
                              ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
