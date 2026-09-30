import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/events/domain_events.dart';
import '../../../../core/layout/responsive.dart';
import '../desktop/batch_detail_desktop_view.dart';
import '../mobile/batch_detail_mobile_view.dart';
import '../providers/exams_provider.dart';
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
  late final StreamSubscription<DomainEvent> _events;
  bool _showSkipped = false;

  /// A result of this exam changed while another page was on top.
  bool _resultsChanged = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<SubmissionBatchesProvider>();
    _events = context.read<DomainEvents>().stream.listen((event) {
      if (event is ExamResultsChanged && event.examId == widget.examId) {
        _resultsChanged = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _watch());
  }

  @override
  void dispose() {
    _events.cancel();
    _provider.stopWatching();
    super.dispose();
  }

  void _watch() => _provider.watch(
    widget.examId,
    widget.batchId,
    // The exam is in memory (this page is opened from it), which tells
    // which class's grades the batch changes.
    teachingPeriodId: context
        .read<ExamsProvider>()
        .detail(widget.examId)
        .data
        ?.teachingPeriodId,
  );

  /// Returning from a review or a photo re-upload re-reads the batch only
  /// if a grade was corrected meanwhile, so it shows up here.
  Future<void> _pushAndRefresh(String location) async {
    _resultsChanged = false;
    await context.push(location);
    if (mounted && _resultsChanged) _watch();
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
