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
/// passes these as the form's `onSubmit`. They return whether the change
/// was saved (the form closes only then).
class SubmissionReviewActions {
  SubmissionReviewActions._();

  /// The exam's class, from the exam in memory (the review is opened from
  /// it): a correction changes that class's grades.
  static int? _classOf(BuildContext context, int examId) =>
      context.read<ExamsProvider>().detail(examId).data?.teachingPeriodId;

  /// [selectedOption] is the letter the student marked, null for
  /// "Sin respuesta".
  static Future<bool> correctAnswer(
    BuildContext context, {
    required int examId,
    required int submissionId,
    required SubmissionAnswer answer,
    required String? selectedOption,
  }) async {
    final error = await context.read<SubmissionsProvider>().correctAnswer(
      examId,
      submissionId,
      answer.questionNumber,
      selectedOption: selectedOption,
      reason: 'Corrección manual del profesor',
      teachingPeriodId: _classOf(context, examId),
    );
    if (!context.mounted) return error == null;
    if (error != null) {
      context.showApiError(error);
      return false;
    }
    context.showSuccess('Respuesta corregida.');
    return true;
  }

  static Future<bool> setFinalGrade(
    BuildContext context, {
    required int examId,
    required int submissionId,
    required double finalGrade,
  }) async {
    final error = await context.read<SubmissionsProvider>().setFinalGrade(
      examId,
      submissionId,
      finalGrade: finalGrade,
      reason: 'Ajuste manual del profesor',
      teachingPeriodId: _classOf(context, examId),
    );
    if (!context.mounted) return error == null;
    if (error != null) {
      context.showApiError(error);
      return false;
    }
    context.showSuccess('Calificación final actualizada.');
    return true;
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

/// Pick the option the student actually marked. Tapping a choice saves it
/// through [onSubmit] (the chip shows it's saving) and closes on success;
/// closing without picking changes nothing.
class CorrectAnswerForm extends StatefulWidget {
  const CorrectAnswerForm({
    super.key,
    required this.answer,
    required this.onSubmit,
  });

  final SubmissionAnswer answer;

  /// Saves the picked letter, or null for "Sin respuesta".
  final Future<bool> Function(String? selectedOption) onSubmit;

  @override
  State<CorrectAnswerForm> createState() => _CorrectAnswerFormState();
}

class _CorrectAnswerFormState extends State<CorrectAnswerForm> {
  bool _saving = false;

  /// The choice being saved: a letter, or '' for "Sin respuesta".
  String? _savingChoice;

  Future<void> _pick(String? letter) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _savingChoice = letter ?? '';
    });
    final ok = await widget.onSubmit(letter);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _savingChoice = null;
    });
    if (ok) Navigator.of(context).pop();
  }

  Widget? _spinnerFor(String choice) => _savingChoice == choice
      ? const SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : null;

  @override
  Widget build(BuildContext context) {
    final answer = widget.answer;
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
                  avatar: _spinnerFor(letter),
                  label: Text(letter),
                  selected: answer.selectedOption == letter,
                  onSelected: _saving ? null : (_) => _pick(letter),
                ),
              ChoiceChip(
                avatar: _spinnerFor(''),
                label: const Text('Sin respuesta'),
                selected: answer.selectedOption == null,
                onSelected: _saving ? null : (_) => _pick(null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Manual final grade within the submission's scale, saved through
/// [onSubmit]; closes on success.
class FinalGradeForm extends StatefulWidget {
  const FinalGradeForm({
    super.key,
    required this.submission,
    required this.onSubmit,
  });

  final SubmissionEntity submission;
  final Future<bool> Function(double finalGrade) onSubmit;

  @override
  State<FinalGradeForm> createState() => _FinalGradeFormState();
}

class _FinalGradeFormState extends State<FinalGradeForm> {
  bool _saving = false;
  late final _controller = TextEditingController(
    text: widget.submission.finalGrade?.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(num min, num max) async {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value < min || value > max) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingresa un valor entre $min y $max.')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSubmit(value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
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
          isLoading: _saving,
          onPressed: () => _submit(min, max),
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
