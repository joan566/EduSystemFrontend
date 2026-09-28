import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/submission_entity.dart';
import '../providers/submissions_provider.dart';
import '../shared/submission_detail_widgets.dart';

/// Mobile: summary, sheet photo, then the answers, stacked.
class SubmissionDetailMobileView extends StatelessWidget {
  const SubmissionDetailMobileView({
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
    final result = await showMobileForm<String?>(
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
    final result = await showMobileForm<double?>(
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
    final state = context.watch<SubmissionsProvider>().detailState;

    return Scaffold(
      appBar: AppBar(title: Text(state.data?.student.name ?? 'Resultado')),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DetailViewState<SubmissionEntity> state,
  ) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<SubmissionsProvider>().loadDetail(
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summary,
            if (image != null) ...[
              const SizedBox(height: 16),
              SubmissionImagePreview(image: image),
            ],
            const SizedBox(height: 16),
            answers,
          ],
        );
    }
  }
}
