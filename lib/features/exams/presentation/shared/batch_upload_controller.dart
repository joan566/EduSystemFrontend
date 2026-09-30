import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../providers/submission_batches_provider.dart';
import 'batch_labels.dart';

/// PDF batch grading upload state: the picked PDF and the "replace
/// existing results" choice. Owned by the page entry point so both survive
/// a mobile <-> desktop switch.
class BatchUploadController extends ChangeNotifier {
  BatchUploadController(this.examId);

  final int examId;

  PickedFile? _file;
  PickedFile? get file => _file;

  bool _replace = false;
  bool get replace => _replace;

  bool _disposed = false;

  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  /// "Retry" on the history.
  void refreshHistory(BuildContext context) =>
      context.read<SubmissionBatchesProvider>().refreshHistory(examId);

  void setReplace(bool value) => _update(() => _replace = value);

  void clearFile() => _update(() => _file = null);

  void pickFile(BuildContext context, PickedFile file) {
    final size = file.size ?? file.bytes.length;
    if (size > AppConfig.maxUploadSizeBytes) {
      context.showError(
        BatchLabels.uploadError(
          const AppException(code: AppErrorCode.fileTooLarge, message: ''),
        )!,
      );
      return;
    }
    _update(() => _file = file);
  }

  Future<void> upload(BuildContext context) async {
    final file = _file;
    if (file == null) return;
    final provider = context.read<SubmissionBatchesProvider>();
    try {
      final batch = await provider.upload(
        examId,
        pdfBytes: file.bytes,
        fileName: file.name,
        replace: _replace,
      );
      clearFile();
      if (context.mounted) await openBatch(context, batch.id);
    } on AppException catch (e) {
      if (!context.mounted) return;
      final message = BatchLabels.uploadError(e);
      if (message != null) {
        context.showError(message);
      } else {
        context.showApiError(e);
      }
    }
  }

  /// The batch screen keeps this exam's history row up to date while it
  /// polls, so nothing is re-read on return.
  Future<void> openBatch(BuildContext context, int batchId) =>
      context.push(RoutePaths.submissionBatch(examId, batchId));

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
