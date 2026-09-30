import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../desktop/submission_detail_desktop_view.dart';
import '../mobile/submission_detail_mobile_view.dart';
import '../providers/submissions_provider.dart';

class SubmissionDetailPage extends StatefulWidget {
  const SubmissionDetailPage({
    super.key,
    required this.examId,
    required this.submissionId,
  });

  final int examId;
  final int submissionId;

  @override
  State<SubmissionDetailPage> createState() => _SubmissionDetailPageState();
}

class _SubmissionDetailPageState extends State<SubmissionDetailPage>
    with SyncedDataState<SubmissionDetailPage> {
  Uint8List? _image;

  /// The review (and its scanned sheet) of a submission already opened
  /// come from memory.
  @override
  Future<void> ensureData() async {
    final provider = context.read<SubmissionsProvider>();
    await provider.ensureDetail(widget.examId, widget.submissionId);
    final submission = provider.detail(widget.examId, widget.submissionId).data;
    if (submission?.hasImage != true || _image != null) return;
    try {
      final bytes = await provider.getImage(widget.examId, widget.submissionId);
      if (mounted) setState(() => _image = Uint8List.fromList(bytes));
    } catch (_) {
      // Image is a nice-to-have for manual review; the answer list
      // still works without it.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => SubmissionDetailMobileView(
        examId: widget.examId,
        submissionId: widget.submissionId,
        image: _image,
      ),
      desktop: (_) => SubmissionDetailDesktopView(
        examId: widget.examId,
        submissionId: widget.submissionId,
        image: _image,
      ),
    );
  }
}
