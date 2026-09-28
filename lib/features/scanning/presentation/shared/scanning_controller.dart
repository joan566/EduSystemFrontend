import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../../exams/presentation/providers/submissions_provider.dart';

/// Answer-sheet capture state (§42-45): the captured/picked image and its
/// upload. The image is uploaded as-is — the backend does the OMR (§45).
/// Owned by the page entry point so a capture survives a layout switch.
class ScanningController extends ChangeNotifier {
  ScanningController(this.examId);

  final int examId;

  Uint8List? _bytes;
  Uint8List? get bytes => _bytes;

  String _fileName = 'hoja.jpg';

  bool _disposed = false;

  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  void setImage(Uint8List bytes, String fileName) => _update(() {
    _bytes = bytes;
    _fileName = fileName;
  });

  void clearImage() => _update(() => _bytes = null);

  Future<void> upload(BuildContext context, {bool replace = false}) async {
    final bytes = _bytes;
    if (bytes == null) return;
    final provider = context.read<SubmissionsProvider>();
    await provider.upload(
      examId,
      imageBytes: bytes,
      fileName: _fileName,
      replace: replace,
    );
    if (!context.mounted) return;

    if (provider.uploadState == UploadState.error) {
      final error = provider.uploadError!;
      if (error.code == 'SUBMISSION_ALREADY_EXISTS') {
        final confirmed = await showAppConfirmDialog(
          context,
          title: 'Este estudiante ya tiene una hoja procesada',
          message:
              '¿Quieres reemplazar el resultado anterior con esta nueva foto?',
          confirmLabel: 'Reemplazar',
          isDestructive: false,
        );
        if (confirmed && context.mounted) {
          await upload(context, replace: true);
        }
        return;
      }
      context.showApiError(error);
    }
  }

  void viewResult(BuildContext context) {
    final submission = context.read<SubmissionsProvider>().lastUploaded!;
    context.pushReplacement(RoutePaths.submissionDetail(examId, submission.id));
  }

  void scanAnother(BuildContext context) {
    context.read<SubmissionsProvider>().resetUpload();
    clearImage();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
