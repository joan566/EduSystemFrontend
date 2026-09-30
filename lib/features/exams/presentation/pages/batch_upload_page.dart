import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../desktop/batch_upload_desktop_view.dart';
import '../mobile/batch_upload_mobile_view.dart';
import '../providers/submission_batches_provider.dart';
import '../shared/batch_upload_controller.dart';

/// PDF batch grading entry point: the teacher uploads one PDF with every
/// scanned sheet (booklets included — they are skipped), then follows the
/// batch on `BatchDetailPage`. Also lists earlier batches so one still
/// running can be picked up again.
class BatchUploadPage extends StatefulWidget {
  const BatchUploadPage({super.key, required this.examId});

  final int examId;

  @override
  State<BatchUploadPage> createState() => _BatchUploadPageState();
}

class _BatchUploadPageState extends State<BatchUploadPage>
    with SyncedDataState<BatchUploadPage> {
  late final _controller = BatchUploadController(widget.examId);

  /// The exam's batch history comes from memory after the first visit;
  /// uploads and the batch screen keep it current.
  @override
  void ensureData() =>
      context.read<SubmissionBatchesProvider>().ensureHistory(widget.examId);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => ResponsiveBuilder(
        mobile: (_) => BatchUploadMobileView(controller: _controller),
        desktop: (_) => BatchUploadDesktopView(controller: _controller),
      ),
    );
  }
}
