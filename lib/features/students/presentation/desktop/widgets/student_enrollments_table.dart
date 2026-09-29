import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/app_empty_state.dart';
import '../../../domain/entities/student_entity.dart';
import '../../shared/student_detail_widgets.dart';
import '../../shared/student_status_chip.dart';

const _flexCourse = 3;
const _flexYear = 2;
const _flexDate = 3;
const _statusWidth = 110.0;
const _actionWidth = 110.0;

/// "Historial académico": every enrollment in one table, newest first,
/// with "Retirar" on the active one.
class StudentEnrollmentsTable extends StatelessWidget {
  const StudentEnrollmentsTable({super.key, required this.detail});

  final StudentDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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

    final header = textTheme.labelMedium?.copyWith(letterSpacing: 0.4);
    Widget head(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text.toUpperCase(), style: header),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                head('Curso', _flexCourse),
                head('Año lectivo', _flexYear),
                head('Matriculado', _flexDate),
                head('Retirado', _flexDate),
                SizedBox(
                  width: _statusWidth,
                  child: Text('ESTADO', style: header),
                ),
                const SizedBox(width: _actionWidth),
              ],
            ),
          ),
          for (final enrollment in enrollments) ...[
            Divider(height: 1, color: colors.outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    flex: _flexCourse,
                    child: Text(
                      enrollment.courseLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: _flexYear,
                    child: Text(
                      '${enrollment.academicYear}',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    flex: _flexDate,
                    child: Text(
                      Formatters.date(enrollment.enrolledAt),
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    flex: _flexDate,
                    child: Text(
                      enrollment.withdrawnAt == null
                          ? '—'
                          : Formatters.date(enrollment.withdrawnAt!),
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  SizedBox(
                    width: _statusWidth,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StudentStatusChip(enrollment: enrollment),
                    ),
                  ),
                  SizedBox(
                    width: _actionWidth,
                    child: enrollment.active
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => StudentDetailActions.withdraw(
                                context,
                                studentId: detail.student.id,
                                enrollment: enrollment,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.error,
                              ),
                              child: const Text('Retirar'),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
