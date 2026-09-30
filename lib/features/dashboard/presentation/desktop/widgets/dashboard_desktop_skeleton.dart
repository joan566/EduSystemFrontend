import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';

/// The desktop home while its first data arrives: placeholders of the
/// greeting hero, the counts strip, "Hoy" with the classes grid, the next
/// class and quick actions, and the activity rail, placed by the same
/// width rules as `DashboardDesktopView`.
class DashboardDesktopSkeleton extends StatelessWidget {
  const DashboardDesktopSkeleton({super.key});

  static const _gap = 20.0;
  static const _railWidth = 340.0;
  static const _railBesideMinWidth = 1180.0;
  static const _splitMinWidth = 860.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Skeleton(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final railBeside = constraints.maxWidth >= _railBesideMinWidth;
            final contentWidth = constraints.maxWidth - 2 * 24;
            final mainWidth = railBeside
                ? contentWidth - _railWidth - _gap
                : contentWidth;
            final main = _Main(split: mainWidth >= _splitMinWidth);
            const rail = DesktopSectionSkeleton(
              rows: 5,
              leading: SkeletonLeading.circle,
            );

            return SkeletonFill(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: railBeside
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: main),
                        const SizedBox(width: _gap),
                        const SizedBox(width: _railWidth, child: rail),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        main,
                        const SizedBox(height: _gap),
                        rail,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _Main extends StatelessWidget {
  const _Main({required this.split});

  final bool split;

  static const _gap = DashboardDesktopSkeleton._gap;

  @override
  Widget build(BuildContext context) {
    const today = DesktopSectionSkeleton(rows: 3, trailingWidth: 90);
    const classes = DesktopSectionSkeleton(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _ClassTile()),
              SizedBox(width: 14),
              Expanded(child: _ClassTile()),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _ClassTile()),
              SizedBox(width: 14),
              Expanded(child: _ClassTile()),
            ],
          ),
        ],
      ),
    );
    const side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopSectionSkeleton(rows: 1, leadingSize: 46),
        SizedBox(height: _gap),
        DesktopSectionSkeleton(rows: 4, leadingSize: 38, trailingWidth: 16),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Hero(),
        const SizedBox(height: _gap),
        const _StatsStrip(),
        const SizedBox(height: _gap),
        if (split)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    today,
                    SizedBox(height: _gap),
                    classes,
                  ],
                ),
              ),
              SizedBox(width: _gap),
              Expanded(flex: 2, child: side),
            ],
          )
        else ...const [
          today,
          SizedBox(height: _gap),
          side,
          SizedBox(height: _gap),
          classes,
        ],
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SkeletonSurface(
      radius: 18,
      color: AppColors.accentBlue.withValues(alpha: 0.05),
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
      child: SizedBox(
        height: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SkeletonText(style: textTheme.bodyMedium, width: 180),
            const SizedBox(height: 6),
            SkeletonText(style: textTheme.headlineLarge, width: 320),
            const SizedBox(height: 8),
            SkeletonText(style: textTheme.bodyMedium, width: 260),
          ],
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SkeletonSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) VerticalDivider(width: 1, color: colors.outline),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const SkeletonCircle(size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonText(
                              style: textTheme.headlineMedium,
                              width: 44,
                            ),
                            const SizedBox(height: 2),
                            SkeletonText(
                              style: textTheme.bodySmall,
                              widthFactor: 0.8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile();

  @override
  Widget build(BuildContext context) {
    return const SkeletonSurface(
      radius: 12,
      padding: EdgeInsets.all(14),
      child: SkeletonTile(leading: SkeletonLeading.square, leadingSize: 42),
    );
  }
}
