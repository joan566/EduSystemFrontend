import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../../../core/widgets/shared/app_download.dart';
import '../providers/exams_provider.dart';

/// Exam-level actions with user feedback, shared by the mobile and desktop
/// views.
class ExamActions {
  ExamActions._();

  static void create(BuildContext context, {required int teachingPeriodId}) {
    context.push('${RoutePaths.examCreate}?teachingPeriodId=$teachingPeriodId');
  }

  /// Deletes the exam; from the detail screen ([popOnSuccess]) it then pops
  /// back to the list.
  static Future<void> delete(
    BuildContext context,
    int examId, {
    bool popOnSuccess = true,
  }) async {
    var deleted = false;
    await showAppConfirmDialog(
      context,
      title: 'Eliminar examen',
      message:
          'Esta acción no se puede deshacer. Se perderán las preguntas configuradas.',
      confirmLabel: 'Eliminar',
      onConfirm: () async {
        final error = await context.read<ExamsProvider>().delete(examId);
        if (!context.mounted) return;
        if (error != null) {
          context.showApiError(error);
        } else {
          deleted = true;
        }
      },
    );
    if (!deleted || !context.mounted) return;
    if (popOnSuccess) Navigator.of(context).pop();
    context.showSuccess('Examen eliminado.');
  }

  /// One PDF with the answer sheets of every active student (§39). It can
  /// take a while, so it's announced at once (it's also triggered from
  /// menus, which close and leave no button to show it).
  static Future<void> downloadAnswerSheets(BuildContext context, int examId) {
    final provider = context.read<ExamsProvider>();
    if (provider.isGeneratingSheets(examId)) {
      context.showInfo('Las hojas de respuesta ya se están generando.');
      return Future.value();
    }
    context.showInfo('Generando las hojas de respuesta…');
    return fetchAndSaveFile(
      context,
      fetch: () => provider.downloadAnswerSheets(examId),
      errorMessage: 'No se pudieron generar las hojas de respuesta.',
    );
  }

  /// A single student's sheet, e.g. for a reprint (§40).
  static Future<void> downloadAnswerSheet(
    BuildContext context,
    int examId,
    int studentId,
  ) {
    final provider = context.read<ExamsProvider>();
    return fetchAndSaveFile(
      context,
      fetch: () => provider.downloadAnswerSheet(examId, studentId),
      errorMessage: 'No se pudo generar la hoja de respuesta.',
    );
  }

  /// A batch finishing there makes this exam's results stale, so they are
  /// re-read on return only then.
  static Future<void> openBatches(BuildContext context, int examId) =>
      context.push(RoutePaths.submissionBatches(examId));

  static void openScanning(BuildContext context, int examId) {
    context.push(RoutePaths.examScanning(examId));
  }
}
