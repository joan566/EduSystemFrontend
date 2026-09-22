import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/submission_entity.dart';
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

class _SubmissionDetailPageState extends State<SubmissionDetailPage> {
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SubmissionsProvider>().loadDetail(
        widget.examId,
        widget.submissionId,
      );
      final submission = context.read<SubmissionsProvider>().detailState.data;
      if (submission?.hasImage == true) {
        final provider = context.read<SubmissionsProvider>();
        try {
          final bytes = await provider.getImage(
            widget.examId,
            widget.submissionId,
          );
          if (mounted) setState(() => _image = Uint8List.fromList(bytes));
        } catch (_) {
          // Image is a nice-to-have for manual review; the answer list
          // still works without it.
        }
      }
    });
  }

  Future<void> _correctAnswer(SubmissionAnswer answer) async {
    final result = await showAppDialog<String?>(
      context,
      child: _CorrectAnswerDialog(answer: answer),
    );
    if (result == _CorrectAnswerDialog.unchanged) return;
    final error = await context.read<SubmissionsProvider>().correctAnswer(
      widget.examId,
      widget.submissionId,
      answer.questionNumber,
      selectedOption: result,
      reason: 'Corrección manual del profesor',
    );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Respuesta corregida.');
    }
  }

  Future<void> _setFinalGrade(SubmissionEntity submission) async {
    final result = await showAppDialog<double?>(
      context,
      child: _FinalGradeDialog(submission: submission),
    );
    if (result == null) return;
    final error = await context.read<SubmissionsProvider>().setFinalGrade(
      widget.examId,
      widget.submissionId,
      finalGrade: result,
      reason: 'Ajuste manual del profesor',
    );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Calificación final actualizada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubmissionsProvider>().detailState;

    return Scaffold(
      appBar: AppBar(title: Text(state.data?.student.name ?? 'Resultado')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(DetailViewState<SubmissionEntity> state) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<SubmissionsProvider>().loadDetail(
            widget.examId,
            widget.submissionId,
          ),
        );
      case DetailStatus.success:
        final submission = state.data!;
        final summary = _SummaryCard(
          submission: submission,
          onSetFinalGrade: () => _setFinalGrade(submission),
        );
        final answers = _AnswersList(
          submission: submission,
          onCorrect: _correctAnswer,
        );

        if (context.isMobile) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              summary,
              if (_image != null) ...[
                const SizedBox(height: 16),
                _ImagePreview(image: _image!),
              ],
              const SizedBox(height: 16),
              answers,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [summary, const SizedBox(height: 20), answers],
              ),
            ),
            if (_image != null)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _ImagePreview(image: _image!),
                ),
              ),
          ],
        );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.submission, required this.onSetFinalGrade});

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

class _AnswersList extends StatelessWidget {
  const _AnswersList({required this.submission, required this.onCorrect});

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

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image});

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

class _CorrectAnswerDialog extends StatelessWidget {
  const _CorrectAnswerDialog({required this.answer});

  static const unchanged = '__unchanged__';

  final SubmissionAnswer answer;

  @override
  Widget build(BuildContext context) {
    final letters = <String>{
      answer.correctOption,
      if (answer.selectedOption != null) answer.selectedOption!,
      ...List.generate(6, (i) => String.fromCharCode(65 + i)),
    }.toList()..sort();

    return AppDialogFrame(
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

class _FinalGradeDialog extends StatefulWidget {
  const _FinalGradeDialog({required this.submission});

  final SubmissionEntity submission;

  @override
  State<_FinalGradeDialog> createState() => _FinalGradeDialogState();
}

class _FinalGradeDialogState extends State<_FinalGradeDialog> {
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
    return AppDialogFrame(
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
