import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../domain/entities/exam_entity.dart';
import 'exam_status_chip.dart';

/// An exam row card: document badge, name, "N preguntas · M estudiantes",
/// readiness chip, date, and an overflow button.
class ExamListCard extends StatelessWidget {
  const ExamListCard({
    super.key,
    required this.exam,
    required this.students,
    required this.onTap,
    required this.onMore,
  });

  final ExamSummaryEntity exam;

  /// Active students of the class; null while unknown.
  final int? students;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);
    final date = exam.evaluationDate;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMore,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TintedIcon(
                icon: Icons.description_outlined,
                color: AppColors.accentBlue,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        exam.numberOfQuestions == 1
                            ? '1 pregunta'
                            : '${exam.numberOfQuestions} preguntas',
                        if (students != null)
                          students == 1
                              ? '1 estudiante'
                              : '$students estudiantes',
                      ].join('  ·  '),
                      style: muted,
                    ),
                    const SizedBox(height: 8),
                    ExamStatusChip(ready: exam.ready),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date == null ? 'Sin fecha' : Formatters.date(date),
                          style: muted,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Más opciones',
                          visualDensity: VisualDensity.compact,
                          onPressed: onMore,
                          icon: const Icon(Icons.more_vert, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
