import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../../../core/widgets/shared/app_download.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../providers/gradebook_provider.dart';

/// Grade-detail mutations with user feedback, shared by both views. How a
/// file is picked (drop zone vs picker button) is up to each view.
class GradebookActions {
  GradebookActions._();

  /// What the backend accepts as an attachment (max. 10 MB).
  static const attachmentExtensions = [
    'pdf', 'doc', 'docx', 'odt', 'rtf', 'txt', //
    'xls', 'xlsx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png',
  ];
  static const maxAttachmentBytes = 10 * 1024 * 1024;

  static Future<void> upload(
    BuildContext context,
    GradeDetailEntity detail,
    PickedFile file,
  ) async {
    if (file.bytes.length > maxAttachmentBytes) {
      context.showWarning('El archivo supera los 10 MB.');
      return;
    }
    final replacing = detail.attachment != null;
    if (replacing) {
      final confirmed = await showAppConfirmDialog(
        context,
        title: 'Reemplazar archivo',
        message:
            'La nota ya tiene "${detail.attachment!.fileName}". ¿Reemplazarlo '
            'por "${file.name}"?',
        confirmLabel: 'Reemplazar',
        isDestructive: false,
      );
      if (!confirmed || !context.mounted) return;
    }
    final error = await context.read<GradebookProvider>().uploadAttachment(
      detail,
      bytes: file.bytes,
      fileName: file.name,
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess(
        replacing ? 'Archivo reemplazado.' : 'Archivo adjuntado.',
      );
    }
  }

  static Future<void> download(
    BuildContext context,
    GradeDetailEntity detail,
  ) {
    final provider = context.read<GradebookProvider>();
    return fetchAndSaveFile(
      context,
      fetch: () => provider.downloadAttachment(detail),
      errorMessage: 'No se pudo descargar el archivo.',
    );
  }

  static Future<void> deleteAttachment(
    BuildContext context,
    GradeDetailEntity detail,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Quitar archivo',
      message: 'Se borrará "${detail.attachment!.fileName}" de esta nota.',
      confirmLabel: 'Quitar',
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<GradebookProvider>().deleteAttachment(
      detail,
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Archivo quitado.');
    }
  }

  static Future<void> deleteRubric(
    BuildContext context,
    GradeDetailEntity detail,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Quitar rúbrica',
      message:
          'Se borran los criterios y los puntajes de todos los estudiantes en '
          '"${detail.evaluation.name}". Las notas ya registradas se conservan.',
      confirmLabel: 'Quitar rúbrica',
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<GradebookProvider>().deleteRubric(detail);
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Rúbrica quitada.');
    }
  }
}
