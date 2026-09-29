import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/app_empty_state.dart';
import '../../../domain/entities/student_entity.dart';
import '../../shared/student_detail_widgets.dart';
import '../../shared/student_status_chip.dart';

/// "Historial académico": every enrollment as a timeline, newest first,
/// with "Retirar" on the active one.
class StudentHistoryTab extends StatelessWidget {
  const StudentHistoryTab({super.key, required this.detail});

  final StudentDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final enrollments = [...detail.enrollments]
      ..sort((a, b) {
        final byYear = b.academicYear.compareTo(a.academicYear);
        return byYear != 0 ? byYear : b.enrolledAt.compareTo(a.enrolledAt);
      });

    if (enrollments.isEmpty) {
      return const AppEmptyState(
        title: 'Sin matrículas registradas',
        message:
            'Este estudiante todavía no ha sido matriculado en ningún curso.',
        icon: Icons.class_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        for (final (i, enrollment) in enrollments.indexed)
          _Entry(
            studentId: detail.student.id,
            enrollment: enrollment,
            last: i == enrollments.length - 1,
          ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.studentId,
    required this.enrollment,
    required this.last,
  });

  final int studentId;
  final StudentEnrollmentEntity enrollment;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = enrollment.active;
    final withdrawnAt = enrollment.withdrawnAt;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? AppColors.accentBlue : colors.surface,
                    border: Border.all(
                      color: active ? AppColors.accentBlue : colors.outline,
                      width: 2,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      color: colors.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active
                        ? AppColors.accentBlue.withValues(alpha: 0.35)
                        : colors.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  enrollment.courseLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${enrollment.academicYear}',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            withdrawnAt == null
                                ? 'Desde ${Formatters.date(enrollment.enrolledAt)}'
                                : '${Formatters.date(enrollment.enrolledAt)} – '
                                      '${Formatters.date(withdrawnAt)}',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          StudentStatusChip(enrollment: enrollment),
                        ],
                      ),
                    ),
                    if (active)
                      TextButton(
                        onPressed: () => StudentDetailActions.withdraw(
                          context,
                          studentId: studentId,
                          enrollment: enrollment,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.error,
                        ),
                        child: const Text('Retirar'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
