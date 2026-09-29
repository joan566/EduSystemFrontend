import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/entities/submission_batch_entity.dart';

/// Owns PDF batch grading for a single exam: upload, batch history and
/// polling of the batch on screen until it finishes. Grading runs on the
/// server, so leaving the page only stops the polling, never the batch.
class SubmissionBatchesProvider extends ChangeNotifier {
  SubmissionBatchesProvider(this._repository);

  final ExamRepository _repository;

  ListViewState<SubmissionBatchSummaryEntity> _history = const ListViewState();
  ListViewState<SubmissionBatchSummaryEntity> get history => _history;

  DetailViewState<SubmissionBatchEntity> _detail = const DetailViewState();
  DetailViewState<SubmissionBatchEntity> get detail => _detail;

  bool _uploading = false;
  bool get uploading => _uploading;

  /// 0..1 while the PDF bytes are being sent; null when unknown.
  double? _uploadProgress;
  double? get uploadProgress => _uploadProgress;

  Timer? _pollTimer;
  int? _pollingExamId;
  int? _pollingBatchId;

  /// Bumped on every [watch]/[stopWatching] so a request still in flight
  /// from an earlier watch can't start a second polling loop.
  int _generation = 0;

  Future<void> loadHistory(int examId) async {
    _history = ListViewState.loading();
    notifyListeners();
    try {
      final batches = await _repository.getSubmissionBatches(examId);
      _history = ListViewState.list(batches);
    } on AppException catch (e) {
      _history = ListViewState.error(e);
    }
    notifyListeners();
  }

  /// Uploads the PDF and returns the queued batch, or throws the
  /// [AppException] from the immediate validation (400/404/413/422).
  Future<SubmissionBatchSummaryEntity> upload(
    int examId, {
    required List<int> pdfBytes,
    required String fileName,
    bool replace = false,
  }) async {
    _uploading = true;
    _uploadProgress = 0;
    notifyListeners();
    try {
      return await _repository.uploadSubmissionBatch(
        examId,
        pdfBytes: pdfBytes,
        fileName: fileName,
        replace: replace,
        onSendProgress: (sent, total) {
          _uploadProgress = total > 0 ? sent / total : null;
          notifyListeners();
        },
      );
    } finally {
      _uploading = false;
      _uploadProgress = null;
      notifyListeners();
    }
  }

  /// Loads the batch and keeps polling it until it is `COMPLETED` or
  /// `FAILED`. Transient poll errors keep the last good data on screen.
  Future<void> watch(int examId, int batchId) async {
    stopWatching();
    _pollingExamId = examId;
    _pollingBatchId = batchId;
    _detail = DetailViewState.loading();
    notifyListeners();
    await _poll(_generation);
  }

  Future<void> _poll(int generation) async {
    final examId = _pollingExamId;
    final batchId = _pollingBatchId;
    if (examId == null || batchId == null) return;
    try {
      final batch = await _repository.getSubmissionBatch(examId, batchId);
      if (generation != _generation) return;
      _detail = DetailViewState.success(batch);
      notifyListeners();
      if (batch.batch.isFinished) {
        _pollTimer = null;
        return;
      }
    } on AppException catch (e) {
      if (generation != _generation) return;
      if (_detail.data == null || !e.isNetwork) {
        _detail = DetailViewState.error(e);
        notifyListeners();
        return;
      }
    }
    _pollTimer = Timer(AppConfig.batchPollInterval, () => _poll(generation));
  }

  void stopWatching() {
    _generation++;
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollingExamId = null;
    _pollingBatchId = null;
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}
