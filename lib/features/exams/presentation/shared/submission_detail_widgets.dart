import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../domain/entities/submission_entity.dart';
import '../providers/exams_provider.dart';
import '../providers/submissions_provider.dart';

/// Manual review mutations with user feedback, shared by both views: each
/// view presents [CorrectAnswerForm] / [FinalGradeForm] its own way and
/// hands the result here.
class SubmissionReviewActions {
  SubmissionReviewActions._();

  /// The exam's class, from the exam in memory (the review is opened from
  /// it): a correction changes that class's grades.
  static int? _classOf(BuildContext context, int examId) =>
      context.read<ExamsProvider>().detail(examId).data?.teachingPeriodId;

  static Future<void> correctAnswer(
    BuildContext context, {
    required int examId,
    required int submissionId,
    required SubmissionAnswer answer,
    required String? result,
  }) async {
    if (result == CorrectAnswerForm.unchanged) return;
    final error = await context.read<SubmissionsProvider>().correctAnswer(
      examId,
      submissionId,
      answer.questionNumber,
      selectedOption: result,
      reason: 'Corrección manual del profesor',
      teachingPeriodId: _classOf(context, examId),
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Respuesta corregida.');
    }
  }

  static Future<void> setFinalGrade(
    BuildContext context, {
    required int examId,
    required int submissionId,
    required double? result,
  }) async {
    if (result == null) return;
    final error = await context.read<SubmissionsProvider>().setFinalGrade(
      examId,
      submissionId,
      finalGrade: result,
      reason: 'Ajuste manual del profesor',
      teachingPeriodId: _classOf(context, examId),
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Calificación final actualizada.');
    }
  }
}

class SubmissionSummaryCard extends StatelessWidget {
  const SubmissionSummaryCard({
    super.key,
    required this.submission,
    required this.onSetFinalGrade,
  });

  final SubmissionEntity submission;
  final VoidCallback onSetFinalGrade;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.student.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      submission.examName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (submission.status == SubmissionStatus.reviewRequired)
                const AppStatusChip(
                  label: 'Requiere revisión',
                  kind: AppStatusKind.warning,
                )
              else if (submission.status == SubmissionStatus.failed)
                const AppStatusChip(label: 'Falló', kind: AppStatusKind.error)
              else
                const AppStatusChip(
                  label: 'Procesado',
                  kind: AppStatusKind.success,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat(
                context,
                '${submission.correctCount}',
                'Correctas',
                AppColors.success,
              ),
              _stat(
                context,
                '${submission.incorrectCount}',
                'Incorrectas',
                AppColors.error,
              ),
              _stat(
                context,
                '${submission.unansweredCount}',
                'Sin responder',
                AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  submission.finalGrade != null &&
                          submission.scaleMinimum != null &&
                          submission.scaleMaximum != null
                      ? Formatters.grade(
                          submission.finalGrade!,
                          submission.scaleMaximum!,
                        )
                      : 'Sin calificación',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              AppButton(
                label: 'Fijar nota manual',
                variant: AppButtonVariant.outlined,
                onPressed: onSetFinalGrade,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: color),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class SubmissionAnswersList extends StatelessWidget {
  const SubmissionAnswersList({
    super.key,
    required this.submission,
    required this.onCorrect,
  });

  final SubmissionEntity submission;
  final void Function(SubmissionAnswer) onCorrect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Respuestas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final answer in submission.answers)
          AppListTile(
            icon: answer.correct == true
                ? Icons.check_circle
                : answer.correct == false
                ? Icons.cancel
                : Icons.remove_circle_outline,
            iconColor: answer.correct == true
                ? AppColors.success
                : answer.correct == false
                ? AppColors.error
                : AppColors.textSecondary,
            background: answer.needsReview
                ? AppColors.warningBg
                : answer.correct == false
                ? AppColors.errorBg.withValues(alpha: 0.4)
                : null,
            title: 'Pregunta ${answer.questionNumber}',
            subtitleMaxLines: 2,
            subtitle: answer.selectedOption == null
                ? 'Sin respuesta · Correcta: ${answer.correctOption}'
                : 'Detectada: ${answer.selectedOption} · Correcta: ${answer.correctOption}'
                      '${answer.detectionStatus == DetectionStatus.manual ? ' (modificada manualmente)' : ''}',
            trailing: TextButton(
              onPressed: () => onCorrect(answer),
              child: const Text('Corregir'),
            ),
          ),
      ],
    );
  }
}

class SubmissionImagePreview extends StatelessWidget {
  const SubmissionImagePreview({super.key, required this.image});

  final Uint8List image;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(image, fit: BoxFit.contain),
      ),
    );
  }
}

/// Pick the option the student actually marked. Pops the letter, null for
/// "Sin respuesta", or [unchanged].
class CorrectAnswerForm extends StatelessWidget {
  const CorrectAnswerForm({super.key, required this.answer});

  static const unchanged = '__unchanged__';

  final SubmissionAnswer answer;

  @override
  Widget build(BuildContext context) {
    final letters = <String>{
      answer.correctOption,
      if (answer.selectedOption != null) answer.selectedOption!,
      ...List.generate(6, (i) => String.fromCharCode(65 + i)),
    }.toList()..sort();

    return AppFormFrame(
      title: 'Corregir pregunta ${answer.questionNumber}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(answer.statement),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final letter in letters.take(6))
                ChoiceChip(
                  label: Text(letter),
                  selected: answer.selectedOption == letter,
                  onSelected: (_) => Navigator.of(context).pop(letter),
                ),
              ChoiceChip(
                label: const Text('Sin respuesta'),
                selected: answer.selectedOption == null,
                onSelected: (_) => Navigator.of(context).pop(null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Manual final grade within the submission's scale; pops the value.
class FinalGradeForm extends StatefulWidget {
  const FinalGradeForm({super.key, required this.submission});

  final SubmissionEntity submission;

  @override
  State<FinalGradeForm> createState() => _FinalGradeFormState();
}

class _FinalGradeFormState extends State<FinalGradeForm> {
  late final _controller = TextEditingController(
    text: widget.submission.finalGrade?.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final min = widget.submission.scaleMinimum ?? 0;
    final max = widget.submission.scaleMaximum ?? 5;
    return AppFormFrame(
      title: 'Fijar nota final',
      actions: [
        AppButton(
          label: 'Guardar',
          onPressed: () {
            final value = double.tryParse(_controller.text.trim());
            if (value == null || value < min || value > max) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ingresa un valor entre $min y $max.')),
              );
              return;
            }
            Navigator.of(context).pop(value);
          },
        ),
      ],
      child: AppTextField(
        controller: _controller,
        label: 'Nota (escala $min - $max)',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}
