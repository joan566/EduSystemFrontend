import 'package:flutter/material.dart';

import '../../../../../core/widgets/mobile/mobile_brand_bar.dart';
import '../../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';

/// The mobile home while its first data arrives: the real brand bar over
/// placeholders of "Hoy", the quick actions, the classes carousel and the
/// recent activity, in the same order and spacing as the home.
class DashboardMobileSkeleton extends StatelessWidget {
  const DashboardMobileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MobileBrandBar(),
          Expanded(
            child: Skeleton(
              child: SkeletonFill(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MobileSectionSkeleton(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SkeletonSurface(
                            radius: 14,
                            padding: EdgeInsets.all(14),
                            child: SkeletonTile(
                              leading: SkeletonLeading.square,
                              leadingSize: 48,
                              gap: 14,
                              titleFactor: 0.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SkeletonRepeat(
                            count: 2,
                            spacing: 14,
                            builder: (context, i) => SkeletonTile(
                              leading: SkeletonLeading.circle,
                              leadingSize: 10,
                              titleFactor: SkeletonRepeat.factor(i),
                              trailingWidth: 48,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    MobileSectionSkeleton(
                      child: Column(
                        children: [
                          for (var row = 0; row < 2; row++) ...[
                            if (row > 0) const SizedBox(height: 10),
                            const Row(
                              children: [
                                Expanded(child: _ActionPill()),
                                SizedBox(width: 10),
                                Expanded(child: _ActionPill()),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const MobileSectionSkeleton(
                      child: SizedBox(
                        height: 108,
                        child: Row(
                          children: [
                            Expanded(child: _CarouselCard()),
                            SizedBox(width: 10),
                            Expanded(child: _CarouselCard()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const MobileSectionSkeleton(
                      leading: SkeletonLeading.circle,
                      leadingSize: 38,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill();

  @override
  Widget build(BuildContext context) {
    return const SkeletonSurface(
      radius: 14,
      padding: EdgeInsets.all(10),
      child: SkeletonTile(
        leading: SkeletonLeading.square,
        leadingSize: 34,
        gap: 8,
        subtitle: false,
        titleFactor: 0.8,
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SkeletonSurface(
      radius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonTile(
            leading: SkeletonLeading.square,
            leadingSize: 44,
            subtitle: false,
            titleFactor: 0.9,
          ),
          const Spacer(),
          SkeletonText(style: textTheme.bodySmall, widthFactor: 0.7),
        ],
      ),
    );
  }
}
