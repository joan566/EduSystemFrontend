import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../providers/exams_provider.dart';
import '../providers/submissions_provider.dart';

/// Exam-level actions with user feedback, shared by the mobile and desktop
/// views.
class ExamActions {
  ExamActions._();

  static void create(BuildContext context, {required int teachingPeriodId}) {
    context.push('${RoutePaths.examCreate}?teachingPeriodId=$teachingPeriodId');
  }

  /// Deletes the exam and pops back to the list.
  static Future<void> delete(BuildContext context, int examId) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar examen',
      message:
          'Esta acción no se puede deshacer. Se perderán las preguntas configuradas.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<ExamsProvider>().delete(examId);
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Batch grading adds submissions in the background, so the results
  /// listing is re-read on return.
  static Future<void> openBatches(BuildContext context, int examId) async {
    await context.push(RoutePaths.submissionBatches(examId));
    if (context.mounted) context.read<SubmissionsProvider>().load(examId);
  }

  static void openScanning(BuildContext context, int examId) {
    context.push(RoutePaths.examScanning(examId));
  }
}
