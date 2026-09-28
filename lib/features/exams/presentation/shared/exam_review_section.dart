import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../domain/entities/exam_entity.dart';

/// Step 3 of [ExamBuilderPage]: a read-only, stateless preview of the exam
/// exactly as it stands before committing it — the counterpart to "revisa
/// antes de guardar" the brief asked for. Also reusable from edit-mode
/// (opened as a sheet from `QuestionsEditor`) since it needs nothing but
/// plain data, not the wizard shell itself.
class ExamReviewSection extends StatelessWidget {
  const ExamReviewSection({
    super.key,
    required this.name,
    required this.description,
    required this.evaluationDate,
    required this.maximumScore,
    required this.questions,
    required this.saving,
    required this.onEdit,
    required this.onSave,
  });

  final String name;
  final String description;
  final DateTime? evaluationDate;
  final double? maximumScore;
  final List<ExamQuestion> questions;
  final bool saving;
  final VoidCallback onEdit;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final incomplete = questions.where((q) => !q.isComplete).length;
    final pointsSum = questions.fold<double>(
      0,
      (sum, q) => sum + (q.points ?? 0),
    );
    final scoreMismatch =
        maximumScore != null &&
        questions.any((q) => q.points != null) &&
        pointsSum != maximumScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Revisa tu examen', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Así queda antes de guardarlo. Puedes volver a editar cuando quieras.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? '(Sin nombre)' : name,
                  style: textTheme.titleMedium,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description, style: textTheme.bodyMedium),
                ],
                const SizedBox(height: 8),
                Text(
                  [
                    if (evaluationDate != null)
                      Formatters.dateTime(evaluationDate!),
                    if (maximumScore != null) 'Puntaje máximo: $maximumScore',
                    '${questions.length} pregunta(s)',
                  ].join(' · '),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (incomplete > 0) ...[
            const SizedBox(height: 12),
            _Banner(
              color: AppColors.warningBg,
              foreground: AppColors.warning,
              icon: Icons.error_outline,
              text:
                  'Hay $incomplete pregunta(s) incompleta(s). No podrás generar hojas hasta completarlas.',
            ),
          ],
          if (scoreMismatch) ...[
            const SizedBox(height: 12),
            _Banner(
              color: AppColors.infoBg,
              foreground: AppColors.info,
              icon: Icons.info_outline,
              text:
                  'La suma de los puntos de las preguntas ($pointsSum) no coincide con el '
                  'puntaje máximo del examen ($maximumScore).',
            ),
          ],
          const SizedBox(height: 20),
          for (var i = 0; i < questions.length; i++) ...[
            _QuestionPreview(index: i, question: questions[i]),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Volver a editar',
                  variant: AppButtonVariant.outlined,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Guardar examen',
                  isLoading: saving,
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.foreground,
    required this.icon,
    required this.text,
  });

  final Color color;
  final Color foreground;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionPreview extends StatelessWidget {
  const _QuestionPreview({required this.index, required this.question});

  final int index;
  final ExamQuestion question;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pregunta ${index + 1}: ${question.statement.isEmpty ? '(sin enunciado)' : question.statement}',
                  style: textTheme.titleMedium,
                ),
              ),
              if (question.points != null)
                Text('${question.points} pts', style: textTheme.bodySmall),
            ],
          ),
          if (!question.isComplete) ...[
            const SizedBox(height: 4),
            Text(
              'Falta: ${question.missingFields.join(', ')}',
              style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ],
          const SizedBox(height: 10),
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  if (option.letter == question.correctOption)
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.success,
                    )
                  else
                    const Icon(
                      Icons.circle_outlined,
                      size: 14,
                      color: AppColors.textDisabled,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${option.letter}. ${option.text.isEmpty ? '(sin texto)' : option.text}',
                      style: option.letter == question.correctOption
                          ? textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            )
                          : textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
