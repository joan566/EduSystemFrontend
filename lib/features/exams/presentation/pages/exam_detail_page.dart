import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/exam_detail_desktop_view.dart';
import '../mobile/exam_detail_mobile_view.dart';
import '../providers/exams_provider.dart';
import '../shared/questions_draft_controller.dart';

class ExamDetailPage extends StatefulWidget {
  const ExamDetailPage({super.key, required this.examId});

  final int examId;

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  // Created once the exam has loaded; lives here so question drafts survive
  // a mobile <-> desktop switch.
  QuestionsDraftController? _questions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ExamsProvider>().loadDetail(widget.examId),
    );
  }

  @override
  void dispose() {
    _questions?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExamsProvider>().detailState.data;
    if (_questions == null && exam != null && exam.id == widget.examId) {
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
        (q) => ExamDetailMobileView(examId: widget.examId, questions: q),
      ),
      desktop: (_) => withQuestions(
        (q) => ExamDetailDesktopView(examId: widget.examId, questions: q),
      ),
    );
  }
}
