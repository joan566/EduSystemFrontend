import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../domain/entities/submission_entity.dart';
import '../providers/submissions_provider.dart';
import '../shared/submission_detail_widgets.dart';

/// Desktop: summary and answers on the left, the scanned sheet on the
/// right for side-by-side checking.
class SubmissionDetailDesktopView extends StatelessWidget {
  const SubmissionDetailDesktopView({
    super.key,
    required this.examId,
    required this.submissionId,
    required this.image,
  });

  final int examId;
  final int submissionId;
  final Uint8List? image;

  Future<void> _correctAnswer(
    BuildContext context,
    SubmissionAnswer answer,
  ) async {
    final result = await showDesktopDialog<String?>(
      context,
      child: CorrectAnswerForm(answer: answer),
    );
    if (!context.mounted) return;
    await SubmissionReviewActions.correctAnswer(
      context,
      examId: examId,
      submissionId: submissionId,
      answer: answer,
      result: result,
    );
  }

  Future<void> _setFinalGrade(
    BuildContext context,
    SubmissionEntity submission,
  ) async {
    final result = await showDesktopDialog<double?>(
      context,
      child: FinalGradeForm(submission: submission),
    );
    if (!context.mounted) return;
    await SubmissionReviewActions.setFinalGrade(
      context,
      examId: examId,
      submissionId: submissionId,
      result: result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubmissionsProvider>().detail(
      examId,
      submissionId,
    );
    final name = state.data?.student.name ?? 'Resultado';

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPageHeader(
            title: name,
            subtitle: state.data?.examName,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DetailViewState<SubmissionEntity> state,
  ) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const DesktopDetailSkeleton(
          actions: 2,
          stats: 3,
          rail: 1,
          railEnd: true,
          sections: 1,
        );
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<SubmissionsProvider>().refreshDetail(
            examId,
            submissionId,
          ),
        );
      case DetailStatus.success:
        final submission = state.data!;
        final summary = SubmissionSummaryCard(
          submission: submission,
          onSetFinalGrade: () => _setFinalGrade(context, submission),
        );
        final answers = SubmissionAnswersList(
          submission: submission,
          onCorrect: (answer) => _correctAnswer(context, answer),
        );
        final image = this.image;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [summary, const SizedBox(height: 20), answers],
              ),
            ),
            if (image != null)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 24, 24),
                  child: SubmissionImagePreview(image: image),
                ),
              ),
          ],
        );
    }
  }
}
