import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/batch_detail_desktop_view.dart';
import '../mobile/batch_detail_mobile_view.dart';
import '../providers/submission_batches_provider.dart';
import '../shared/batch_detail_widgets.dart';

/// Progress and results of one PDF batch. Polls while the batch runs;
/// pages appear as they are resolved. Grades are read fresh on every
/// poll, so manual corrections show up here too.
class BatchDetailPage extends StatefulWidget {
  const BatchDetailPage({
    super.key,
    required this.examId,
    required this.batchId,
  });

  final int examId;
  final int batchId;

  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage> {
  late final SubmissionBatchesProvider _provider;
  bool _showSkipped = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<SubmissionBatchesProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _watch());
  }

  @override
  void dispose() {
    _provider.stopWatching();
    super.dispose();
  }

  void _watch() => _provider.watch(widget.examId, widget.batchId);

  /// Returning from a review or a photo re-upload re-reads the batch so
  /// the corrected grade and averages show up.
  Future<void> _pushAndRefresh(String location) async {
    await context.push(location);
    if (mounted) _watch();
  }

  @override
  Widget build(BuildContext context) {
    final props = BatchDetailViewProps(
      examId: widget.examId,
      showSkipped: _showSkipped,
      onShowSkippedChanged: (value) => setState(() => _showSkipped = value),
      onRetry: _watch,
      onNavigate: _pushAndRefresh,
    );
    return ResponsiveBuilder(
      mobile: (_) => BatchDetailMobileView(props: props),
      desktop: (_) => BatchDetailDesktopView(props: props),
    );
  }
}
