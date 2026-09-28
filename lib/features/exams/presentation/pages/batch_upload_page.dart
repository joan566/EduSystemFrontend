import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/batch_upload_desktop_view.dart';
import '../mobile/batch_upload_mobile_view.dart';
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

class _BatchUploadPageState extends State<BatchUploadPage> {
  late final _controller = BatchUploadController(widget.examId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.loadHistory(context),
    );
  }

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
