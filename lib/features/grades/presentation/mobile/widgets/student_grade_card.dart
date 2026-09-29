import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/grading_entities.dart';
import '../../shared/grade_labels.dart';
import '../../shared/initials.dart';

/// A student row card: initials, name and code, period grade and status.
class StudentGradeCard extends StatelessWidget {
  const StudentGradeCard({
    super.key,
    required this.student,
    required this.scale,
    required this.onTap,
  });

  final StudentPeriodGrade student;
  final GradingScaleEntity scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Identity tint per student, so neighbours are easy to tell apart.
    final tint =
        AppColors.accents[student.studentId % AppColors.accents.length];
    final grade = student.periodGrade;
    final dot = switch (student.passing) {
      true => AppColors.success,
      false => AppColors.error,
      null => AppColors.accentBlue,
    };

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: tint.withValues(alpha: 0.12),
                child: Text(
                  initialsOf(student.studentName),
                  style: textTheme.titleSmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Código: ${student.studentCode}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (grade != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        periodGradeLabel(grade, scale),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    child: GradeStatusChip(
                      passing: student.passing,
                      hasGrade: grade != null,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
