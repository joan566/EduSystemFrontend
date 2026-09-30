import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../providers/submission_batches_provider.dart';
import '../shared/batch_detail_widgets.dart';

/// Desktop: status card beside a 3×2 grid of result figures, then the
/// pages with outcome chips.
class BatchDetailDesktopView extends StatelessWidget {
  const BatchDetailDesktopView({super.key, required this.props});

  final BatchDetailViewProps props;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubmissionBatchesProvider>().detail;
    final title = state.data?.batch.fileName ?? 'Lote de hojas';

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPageHeader(
            title: title,
            breadcrumbs: ['Calificar PDF', title],
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: switch (state.status) {
              DetailStatus.initial || DetailStatus.loading => const Skeleton(
                child: SkeletonFill(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DesktopStatsRowSkeleton(),
                      SizedBox(height: 20),
                      DesktopSectionSkeleton(rows: 6, trailingWidth: 90),
                    ],
                  ),
                ),
              ),
              DetailStatus.error => AppErrorState(
                exception: state.error!,
                onRetry: props.onRetry,
              ),
              DetailStatus.success => ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: BatchStatusCard(batch: state.data!.batch),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.2,
                          children: [
                            for (final (label, value, color)
                                in batchResultItems(state.data!.results))
                              BatchResultFigure(
                                label: label,
                                value: value,
                                color: color,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  BatchPagesList(
                    data: state.data!,
                    props: props,
                    showOutcomeChip: true,
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}
