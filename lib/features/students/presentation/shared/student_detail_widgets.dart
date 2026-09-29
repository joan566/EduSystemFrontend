import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';

/// Student-detail mutations with user feedback, shared by both views.
class StudentDetailActions {
  StudentDetailActions._();

  /// Copies e.g. the student's code or email, with a confirmation.
  static Future<void> copy(
    BuildContext context,
    String label,
    String value,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) context.showSuccess('$label copiado.');
  }

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
