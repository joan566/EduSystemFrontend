import 'package:flutter/material.dart';

import '../../errors/app_exception.dart';
import '../../extensions/context_extensions.dart';
import '../../network/api_client.dart';
import '../../utils/downloads.dart';
import 'app_confirm_dialog.dart';

/// Fetches a file, lets the user choose where to save it ("Guardar como"),
/// and then says exactly where it went. [errorMessage] is shown when the
/// file couldn't be generated for a reason other than an API error.
Future<void> fetchAndSaveFile(
  BuildContext context, {
  required Future<BinaryDownload> Function() fetch,
  required String errorMessage,
}) async {
  final BinaryDownload download;
  try {
    download = await fetch();
  } on AppException catch (e) {
    if (context.mounted) context.showApiError(e);
    return;
  } catch (_) {
    if (context.mounted) context.showError(errorMessage);
    return;
  }
  if (!context.mounted) return;

  try {
    SavedDownload? saved;
    try {
      saved = await Downloads.save(download);
    } on DownloadNeedsUserGesture {
      // Web only: the file took long enough that the browser no longer
      // counts the original click, so the save picker needs a new one.
      if (!context.mounted) return;
      final confirmed = await showAppConfirmDialog(
        context,
        title: 'Archivo listo',
        message: '«${download.fileName}» está listo. Elige dónde guardarlo.',
        confirmLabel: 'Guardar como…',
        isDestructive: false,
      );
      if (!confirmed) return;
      saved = await Downloads.save(download, browserFallback: true);
    }
    if (!context.mounted) return;
    if (saved == null) {
      context.showInfo('Guardado cancelado.');
    } else {
      context.showSuccess(
        saved.message,
        duration: const Duration(seconds: 8),
      );
    }
  } catch (_) {
    if (context.mounted) context.showError('No se pudo guardar el archivo.');
  }
}
