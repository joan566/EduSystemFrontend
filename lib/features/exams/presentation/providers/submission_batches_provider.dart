import 'dart:async';

import '../../../../core/cache/keyed_cache.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/entities/submission_batch_entity.dart';

/// Owns PDF batch grading: upload, each exam's batch history (cached per
/// exam) and polling of the batch on screen until it finishes. Grading runs
/// on the server, so leaving the page only stops the polling, never the
/// batch; the session ending stops it too (this provider is disposed).
///
/// Polling is deliberately not a cache. When it sees a batch finish, the
/// exam's results change, which is announced ([ExamResultsChanged]) so the
/// results and the class's grades are re-read when next shown.
class SubmissionBatchesProvider extends SessionNotifier {
  SubmissionBatchesProvider(this._repository, DomainEvents events)
    : super(events);

  final ExamRepository _repository;

  late final _histories = keyedCache<int, List<SubmissionBatchSummaryEntity>>();

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
  int? _pollingClassId;

  /// Bumped on every [watch]/[stopWatching] so a request still in flight
  /// from an earlier watch can't start a second polling loop.
  int _generation = 0;

  // --- History per exam ----------------------------------------------------

  ListViewState<SubmissionBatchSummaryEntity> history(int examId) =>
      _histories.view(examId);

  Future<void> ensureHistory(int examId) =>
      _histories.ensure(examId, () => _repository.getSubmissionBatches(examId));

  Future<void> refreshHistory(int examId) => _histories.refresh(
    examId,
    () => _repository.getSubmissionBatches(examId),
  );

  // --- Upload --------------------------------------------------------------

  /// Uploads the PDF and returns the queued batch (also added to the exam's
  /// history), or throws the [AppException] from the immediate validation
  /// (400/404/413/422).
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
      final batch = await _repository.uploadSubmissionBatch(
        examId,
        pdfBytes: pdfBytes,
        fileName: fileName,
        replace: replace,
        onSendProgress: (sent, total) {
          _uploadProgress = total > 0 ? sent / total : null;
          notifyListeners();
        },
      );
      _histories.update(examId, (list) => _withBatch(list, batch));
      return batch;
    } finally {
      _uploading = false;
      _uploadProgress = null;
      notifyListeners();
    }
  }

  // --- Polling -------------------------------------------------------------

  /// Loads the batch and keeps polling it until it is `COMPLETED` or
  /// `FAILED`. Transient poll errors keep the last good data on screen.
  /// [teachingPeriodId] (the exam's class, when known) scopes what the
  /// batch finishing makes stale.
  Future<void> watch(int examId, int batchId, {int? teachingPeriodId}) async {
    stopWatching();
    _pollingExamId = examId;
    _pollingBatchId = batchId;
    _pollingClassId = teachingPeriodId;
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
      final wasFinished = _knownFinished(examId, batchId);
      _detail = DetailViewState.success(batch);
      _histories.update(examId, (list) => _withBatch(list, batch.batch));
      if (batch.batch.isFinished && wasFinished != true) {
        _announceResults(examId);
      }
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

  /// Whether [batchId] was already known to be finished (null: unknown).
  bool? _knownFinished(int examId, int batchId) {
    final polled = _detail.data?.batch;
    if (polled != null && polled.id == batchId) return polled.isFinished;
    return _histories
        .dataOf(examId)
        ?.where((b) => b.id == batchId)
        .firstOrNull
        ?.isFinished;
  }

  /// The batch graded the exam's sheets: its results and its class's
  /// grades are now stale.
  void _announceResults(int examId) {
    final teachingPeriodId = _pollingClassId;
    publish(ExamResultsChanged(examId, teachingPeriodId: teachingPeriodId));
    if (teachingPeriodId != null) {
      publish(ClassDataChanged(teachingPeriodId, const {ClassAspect.grades}));
    }
  }

  /// [list] with [batch] inserted (newest first, like the API) or replaced.
  static List<SubmissionBatchSummaryEntity> _withBatch(
    List<SubmissionBatchSummaryEntity> list,
    SubmissionBatchSummaryEntity batch,
  ) => [
    for (final b in list)
      if (b.id != batch.id) b,
    batch,
  ]..sort((a, b) => b.id.compareTo(a.id));

  void stopWatching() {
    _generation++;
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollingExamId = null;
    _pollingBatchId = null;
    _pollingClassId = null;
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}
