import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';

/// Student-detail mutations with user feedback, shared by both views.
class StudentDetailActions {
  StudentDetailActions._();

  static Future<void> withdraw(
    BuildContext context, {
    required int studentId,
    required StudentEnrollmentEntity enrollment,
  }) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Retirar estudiante',
      message:
          'El estudiante se retirará de ${enrollment.courseLabel}. Se conservará su historial.',
      confirmLabel: 'Retirar',
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<StudentsProvider>().withdraw(
      studentId,
      enrollment.groupId,
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Estudiante retirado del curso.');
    }
  }
}

/// One enrollment in a student's history, with a withdraw action while
/// it's active.
class StudentEnrollmentTile extends StatelessWidget {
  const StudentEnrollmentTile({
    super.key,
    required this.studentId,
    required this.enrollment,
  });

  final int studentId;
  final StudentEnrollmentEntity enrollment;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      icon: Icons.class_outlined,
      title: enrollment.courseLabel,
      subtitle: enrollment.withdrawnAt == null
          ? 'Matriculado desde ${Formatters.date(enrollment.enrolledAt)}'
          : 'Matriculado ${Formatters.date(enrollment.enrolledAt)} — '
                'retirado ${Formatters.date(enrollment.withdrawnAt!)}',
      trailing: enrollment.active
          ? TextButton(
              onPressed: () => StudentDetailActions.withdraw(
                context,
                studentId: studentId,
                enrollment: enrollment,
              ),
              child: const Text('Retirar'),
            )
          : const AppStatusChip(label: 'Retirado', kind: AppStatusKind.neutral),
    );
  }
}

class StudentInfoRow extends StatelessWidget {
  const StudentInfoRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
