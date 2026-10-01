import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
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
    await showAppConfirmDialog(
      context,
      title: 'Retirar estudiante',
      message:
          'El estudiante se retirará de ${enrollment.courseLabel}. Se conservará su historial.',
      confirmLabel: 'Retirar',
      onConfirm: () async {
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
      },
    );
  }

  /// Permanent delete of the student and everything tied to them. The
  /// dialog points to "Retirar" for the common case of leaving a group.
  /// On success leaves the (now gone) detail screen.
  static Future<void> delete(
    BuildContext context, {
    required StudentEntity student,
  }) async {
    var deleted = false;
    await showAppConfirmDialog(
      context,
      title: 'Eliminar estudiante',
      message:
          'Se eliminará definitivamente a ${student.fullName} junto con sus '
          'notas, asistencia, observaciones, hojas de respuesta y archivos '
          'adjuntos. Esta acción no se puede deshacer.\n\n'
          'Si solo quieres sacarlo de un grupo, usa "Retirar": así se '
          'conserva su historial.',
      confirmLabel: 'Eliminar definitivamente',
      onConfirm: () async {
        final error = await context.read<StudentsProvider>().delete(student.id);
        if (!context.mounted) return;
        if (error != null) {
          context.showApiError(error);
        } else {
          deleted = true;
        }
      },
    );
    if (!deleted || !context.mounted) return;
    context.showSuccess('Estudiante eliminado.');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.students);
    }
  }
}
