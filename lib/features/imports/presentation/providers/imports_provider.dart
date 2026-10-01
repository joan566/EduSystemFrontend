import 'dart:async';

import '../../../../core/cache/cached_value.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/import_repository.dart';
import '../../domain/entities/import_batch_entity.dart';

/// Where an upload is: sending the file, waiting on the server, done, or
/// no longer followed ([timedOut]: no progress for
/// [ImportsProvider.stallTimeout]; [lost]: its state couldn't be read).
enum ImportPhase { uploading, queued, processing, finished, timedOut, lost }

/// The latest upload of one [ImportType], as its card shows it.
class ImportRun {
  const ImportRun({
    required this.phase,
    this.uploadProgress,
    this.batch,
    this.result,
  });

  final ImportPhase phase;

  /// 0..1 while the file is being sent; null when unknown.
  final double? uploadProgress;

  /// The import as last read (null while the file is still being sent).
  final ImportBatchEntity? batch;

  /// The finished import with its row errors ([ImportPhase.finished]).
  final ImportResultEntity? result;

  bool get isActive =>
      phase == ImportPhase.uploading ||
      phase == ImportPhase.queued ||
      phase == ImportPhase.processing;

  /// No longer followed before it finished ([ImportPhase.timedOut] or
  /// [ImportPhase.lost]).
  bool get isUnresolved =>
      phase == ImportPhase.timedOut || phase == ImportPhase.lost;
}

/// Imports and their history. The backend processes an upload in the
/// background, so this sends the file, then polls the import until it
/// finishes — like PDF batch grading, leaving the screen doesn't stop it;
/// the session ending does (this provider is disposed). Only one import
/// can run at a time (the backend answers 409 `IMPORT_IN_PROGRESS`).
///
/// Every finished import that got past reading the file announces
/// [SessionDataReset]: any import can touch students, enrollments, classes,
/// grades and attendance at once, so the whole session is re-read, as on
/// signing in.
class ImportsProvider extends SessionNotifier {
  ImportsProvider(
    this._repository,
    DomainEvents events, {
    this.pollInterval = AppConfig.batchPollInterval,
    this.stallTimeout = const Duration(minutes: 3),
  }) : super(events);

  final ImportRepository _repository;

  /// How often a running import is re-read.
  final Duration pollInterval;

  /// After this long without progress (same status, row and sheet) an
  /// import is no longer polled; the history shows how it ended. A large
  /// import that keeps advancing is followed to the end.
  final Duration stallTimeout;

  /// The latest imports (first page).
  late final _history = cachedValue<ApiPage<ImportBatchEntity>>();

  ListViewState<ImportBatchEntity> get historyState => _history.view;

  /// Reads the history if needed, then follows an import still running
  /// (e.g. after reloading the page). With an import no longer followed it
  /// re-reads it, to find out how that one ended.
  Future<void> ensureHistory() async {
    if (_runs.values.any((r) => r.isUnresolved)) {
      await _history.refresh(_repository.getHistory);
    } else {
      await _history.ensure(_repository.getHistory);
    }
    _resumeActive();
  }

  /// Re-reads the history ("retry"), then follows an import still running.
  Future<void> refreshHistory() async {
    await _history.refresh(_repository.getHistory);
    _resumeActive();
  }

  final Map<ImportType, ImportRun> _runs = {};

  ImportRun? run(ImportType type) => _runs[type];

  /// An upload is being sent or processed: the backend accepts no other.
  bool get hasActiveImport => _runs.values.any((r) => r.isActive);

  /// The upload being sent or processed, if any (only one at a time).
  ({ImportType type, ImportRun run})? get activeImport {
    for (final MapEntry(:key, :value) in _runs.entries) {
      if (value.isActive) return (type: key, run: value);
    }
    return null;
  }

  Timer? _pollTimer;
  int? _watchedId;
  ImportType? _watchedType;

  /// Polls in a row that found the import where it was.
  int _stalledPolls = 0;

  /// Bumped on every [_watch]/[_stopWatching] so a request still in flight
  /// from an earlier watch can't start a second polling loop.
  int _generation = 0;

  Future<BinaryDownload> downloadTemplate() => _repository.downloadTemplate();

  Future<BinaryDownload> downloadSchoolSetupTemplate() =>
      _repository.downloadSchoolSetupTemplate();

  Future<BinaryDownload> downloadErrorReport(int importId) =>
      _repository.downloadErrorReport(importId);

  Future<String?> getFailureReason(int batchId) =>
      _repository.getFailureReason(batchId);

  /// Sends the file and starts following the queued import. Returns the
  /// error of a rejected upload (empty or non-.xlsx file, too large, class
  /// not found, another import running), or null once it is queued. On
  /// `IMPORT_IN_PROGRESS` the running import is looked up and followed.
  /// [teachingPeriodId] is required for [ImportType.teachingPeriod].
  Future<AppException?> upload(
    ImportType type, {
    required String fileName,
    required List<int> bytes,
    int? teachingPeriodId,
  }) async {
    _runs[type] = const ImportRun(
      phase: ImportPhase.uploading,
      uploadProgress: 0,
    );
    notifyListeners();
    void onSendProgress(int sent, int total) {
      if (_runs[type]?.phase != ImportPhase.uploading) return;
      _runs[type] = ImportRun(
        phase: ImportPhase.uploading,
        uploadProgress: total > 0 ? sent / total : null,
      );
      notifyListeners();
    }

    try {
      final batch = await switch (type) {
        ImportType.students => _repository.uploadStudents(
          fileName: fileName,
          bytes: bytes,
          onSendProgress: onSendProgress,
        ),
        ImportType.teachingPeriod => _repository.uploadTeachingPeriod(
          teachingPeriodId: teachingPeriodId!,
          fileName: fileName,
          bytes: bytes,
          onSendProgress: onSendProgress,
        ),
        ImportType.schoolSetup => _repository.uploadSchoolSetup(
          fileName: fileName,
          bytes: bytes,
          onSendProgress: onSendProgress,
        ),
      };
      _history.update((page) => _withBatch(page, batch));
      _watch(batch, type);
      return null;
    } on AppException catch (e) {
      _runs.remove(type);
      notifyListeners();
      if (e.code == AppErrorCode.importInProgress) unawaited(refreshHistory());
      return e;
    }
  }

  /// Clears a finished upload's result from its card. A running one stays.
  void dismiss(ImportType type) {
    if (_runs[type]?.isActive ?? false) return;
    if (_runs.remove(type) != null) notifyListeners();
  }

  // --- Polling -------------------------------------------------------------

  void _resumeActive() {
    if (_watchedId != null) return;
    final history = _history.data?.content ?? const <ImportBatchEntity>[];
    final active = history.where((b) => b.isActive).firstOrNull;
    final type = active?.type;
    if (active != null && type != null) {
      _watch(active, type);
      return;
    }
    // One given up on that has since finished: one more read shows its
    // result and announces it.
    for (final MapEntry(key: type, value: run) in _runs.entries) {
      final id = run.batch?.id;
      if (!run.isUnresolved || id == null) continue;
      final ended = history.where((b) => b.id == id && b.isFinished);
      if (ended.isNotEmpty) {
        _watch(ended.first, type);
        return;
      }
    }
  }

  void _watch(ImportBatchEntity batch, ImportType type) {
    _stopWatching();
    _watchedId = batch.id;
    _watchedType = type;
    _runs[type] = ImportRun(
      phase: batch.isFinished ? ImportPhase.processing : _phaseOf(batch),
      batch: batch,
    );
    notifyListeners();
    _schedule(_generation);
  }

  void _schedule(int generation) {
    _pollTimer = Timer(pollInterval, () => _poll(generation));
  }

  Future<void> _poll(int generation) async {
    final id = _watchedId;
    final type = _watchedType;
    if (id == null || type == null) return;
    _stalledPolls++;
    try {
      final result = await _repository.getImport(id);
      if (generation != _generation) return;
      final batch = result.batch;
      _history.update((page) => _withBatch(page, batch));
      if (batch.isFinished) {
        _runs[type] = ImportRun(
          phase: ImportPhase.finished,
          batch: batch,
          result: result,
        );
        _announce(batch);
        _stopWatching();
        notifyListeners();
        return;
      }
      if (_advanced(_runs[type]?.batch, batch)) _stalledPolls = 0;
      _runs[type] = ImportRun(phase: _phaseOf(batch), batch: batch);
      notifyListeners();
    } on AppException catch (e) {
      if (generation != _generation) return;
      // A dropped connection keeps polling; anything else won't fix itself.
      if (!e.isNetwork) {
        _giveUp(type, ImportPhase.lost);
        return;
      }
    }
    if (pollInterval * _stalledPolls >= stallTimeout) {
      _giveUp(type, ImportPhase.timedOut);
      return;
    }
    _schedule(generation);
  }

  void _giveUp(ImportType type, ImportPhase phase) {
    _runs[type] = ImportRun(phase: phase, batch: _runs[type]?.batch);
    _stopWatching();
    notifyListeners();
  }

  static ImportPhase _phaseOf(ImportBatchEntity batch) =>
      batch.status == ImportStatus.queued
      ? ImportPhase.queued
      : ImportPhase.processing;

  /// The import moved since it was last read.
  static bool _advanced(ImportBatchEntity? before, ImportBatchEntity now) =>
      before == null ||
      before.status != now.status ||
      before.processedRows != now.processedRows ||
      before.currentStep != now.currentStep;

  /// Re-reads the whole session after an import. A file rejected as a
  /// whole changed nothing.
  void _announce(ImportBatchEntity batch) {
    if (batch.failedWholeFile) return;
    publish(const SessionDataReset());
  }

  /// [page] with [batch] replaced, or added first (newest first, like the
  /// API).
  static ApiPage<ImportBatchEntity> _withBatch(
    ApiPage<ImportBatchEntity> page,
    ImportBatchEntity batch,
  ) {
    final known = page.content.any((b) => b.id == batch.id);
    return ApiPage(
      content: known
          ? [for (final b in page.content) b.id == batch.id ? batch : b]
          : [batch, ...page.content],
      page: page.page,
      totalPages: page.totalPages,
      totalElements: page.totalElements + (known ? 0 : 1),
    );
  }

  void _stopWatching() {
    _generation++;
    _pollTimer?.cancel();
    _pollTimer = null;
    _watchedId = null;
    _watchedType = null;
    _stalledPolls = 0;
  }

  @override
  void dispose() {
    _stopWatching();
    super.dispose();
  }
}
