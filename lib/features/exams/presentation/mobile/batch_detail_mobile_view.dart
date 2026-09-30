import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../providers/submission_batches_provider.dart';
import '../shared/batch_detail_widgets.dart';

/// Mobile: status, a two-column grid of result figures, then the pages.
class BatchDetailMobileView extends StatelessWidget {
  const BatchDetailMobileView({super.key, required this.props});

  final BatchDetailViewProps props;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubmissionBatchesProvider>().detail;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.data?.batch.fileName ?? 'Lote de hojas'),
      ),
      body: switch (state.status) {
        DetailStatus.initial ||
        DetailStatus.loading => const MobileDetailSkeleton(
          avatar: SkeletonLeading.square,
          stats: 2,
          sections: 1,
          rowsPerSection: 5,
        ),
        DetailStatus.error => AppErrorState(
          exception: state.error!,
          onRetry: props.onRetry,
        ),
        DetailStatus.success => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BatchStatusCard(batch: state.data!.batch),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: [
                for (final (label, value, color) in batchResultItems(
                  state.data!.results,
                ))
                  BatchResultFigure(label: label, value: value, color: color),
              ],
            ),
            const SizedBox(height: 20),
            BatchPagesList(
              data: state.data!,
              props: props,
              showOutcomeChip: false,
            ),
          ],
        ),
      },
    );
  }
}
