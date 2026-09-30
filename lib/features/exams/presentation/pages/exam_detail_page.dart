import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../desktop/exam_detail_desktop_view.dart';
import '../mobile/exam_detail_mobile_view.dart';
import '../providers/exams_provider.dart';
import '../shared/questions_draft_controller.dart';

class ExamDetailPage extends StatefulWidget {
  const ExamDetailPage({super.key, required this.examId, this.initialTab = 0});

  final int examId;
  final int initialTab;

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage>
    with SyncedDataState<ExamDetailPage> {
  // Created once the exam has loaded; lives here so question drafts survive
  // a mobile <-> desktop switch.
  QuestionsDraftController? _questions;
  late int _tab = widget.initialTab.clamp(0, 2);

  @override
  void ensureData() {
    context.read<ExamsProvider>().ensureDetail(widget.examId);
    // The class name and roster size shown in the header come from here.
    context.read<TeachingProvider>().ensureAllPeriodsLoaded();
  }

  @override
  void dispose() {
    _questions?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamsProvider>().detail(widget.examId).data;
    if (_questions == null && exam != null) {
      _questions = QuestionsDraftController(exam);
    }
    final questions = _questions;

    Widget withQuestions(Widget Function(QuestionsDraftController?) build) =>
        questions == null
        ? build(null)
        : ListenableBuilder(
            listenable: questions,
            builder: (_, _) => build(questions),
          );

    return ResponsiveBuilder(
      mobile: (_) => withQuestions(
        (q) => ExamDetailMobileView(
          examId: widget.examId,
          questions: q,
          tab: _tab,
          onTabChanged: (tab) => setState(() => _tab = tab),
        ),
      ),
      desktop: (_) => withQuestions(
        (q) => ExamDetailDesktopView(
          examId: widget.examId,
          questions: q,
          tab: _tab,
          onTabChanged: (tab) => setState(() => _tab = tab),
        ),
      ),
    );
  }
}
