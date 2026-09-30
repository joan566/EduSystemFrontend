import '../../../../core/cache/cached_value.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/import_repository.dart';
import '../../domain/entities/import_batch_entity.dart';

enum UploadStatus { idle, uploading, done, error }

/// Imports and their history. An import changes data other screens have
/// cached, so each successful upload announces what it touched:
/// students ([StudentsChanged]), one class ([ClassDataChanged.all]) or —
/// the school-setup workbook, which can create anything —
/// everything ([SessionDataReset]).
class ImportsProvider extends SessionNotifier {
  ImportsProvider(this._repository, DomainEvents events) : super(events);

  final ImportRepository _repository;

  /// The latest imports (first page).
  late final _history = cachedValue<ApiPage<ImportBatchEntity>>();

  ListViewState<ImportBatchEntity> get historyState => _history.view;

  Future<void> ensureHistory() => _history.ensure(_repository.getHistory);

  /// Re-reads the history (after an upload adds a batch, or "retry").
  Future<void> refreshHistory() => _history.refresh(_repository.getHistory);

  UploadStatus _uploadStatus = UploadStatus.idle;
  UploadStatus get uploadStatus => _uploadStatus;

  ImportResultEntity? _lastResult;
  ImportResultEntity? get lastResult => _lastResult;

  AppException? _uploadError;
  AppException? get uploadError => _uploadError;

  // Combined teaching-period import (Students + Grades + Attendance).
  // Kept separate from the student-only upload state above so both flows
  // can live on the same screen without clobbering each other.
  UploadStatus _periodUploadStatus = UploadStatus.idle;
  UploadStatus get periodUploadStatus => _periodUploadStatus;

  ImportResultEntity? _periodLastResult;
  ImportResultEntity? get periodLastResult => _periodLastResult;

  AppException? _periodUploadError;
  AppException? get periodUploadError => _periodUploadError;

  // School-wide bootstrap import (periods/grades/subjects/groups/classes/
  // students/activities/grades/attendance in one 9-sheet workbook). Not
  // scoped to any teaching period, so it gets its own state too.
  UploadStatus _schoolSetupUploadStatus = UploadStatus.idle;
  UploadStatus get schoolSetupUploadStatus => _schoolSetupUploadStatus;

  ImportResultEntity? _schoolSetupLastResult;
  ImportResultEntity? get schoolSetupLastResult => _schoolSetupLastResult;

  AppException? _schoolSetupUploadError;
  AppException? get schoolSetupUploadError => _schoolSetupUploadError;

  Future<BinaryDownload> downloadTemplate() => _repository.downloadTemplate();

  Future<BinaryDownload> downloadErrorReport(int importId) =>
      _repository.downloadErrorReport(importId);

  Future<String?> getFailureReason(int batchId) =>
      _repository.getFailureReason(batchId);

  Future<void> upload({
    required String fileName,
    required List<int> bytes,
  }) async {
    _uploadStatus = UploadStatus.uploading;
    _uploadError = null;
    _lastResult = null;
    notifyListeners();
    try {
      _lastResult = await _repository.uploadStudents(
        fileName: fileName,
        bytes: bytes,
      );
      _uploadStatus = UploadStatus.done;
      publish(const StudentsChanged());
      await refreshHistory();
    } on AppException catch (e) {
      _uploadStatus = UploadStatus.error;
      _uploadError = e;
    }
    notifyListeners();
  }

  void resetUpload() {
    _uploadStatus = UploadStatus.idle;
    _lastResult = null;
    _uploadError = null;
    notifyListeners();
  }

  Future<void> uploadTeachingPeriod({
    required int teachingPeriodId,
    required String fileName,
    required List<int> bytes,
  }) async {
    _periodUploadStatus = UploadStatus.uploading;
    _periodUploadError = null;
    _periodLastResult = null;
    notifyListeners();
    try {
      _periodLastResult = await _repository.uploadTeachingPeriod(
        teachingPeriodId: teachingPeriodId,
        fileName: fileName,
        bytes: bytes,
      );
      _periodUploadStatus = UploadStatus.done;
      // Students, grades and attendance of that class.
      publish(ClassDataChanged.all(teachingPeriodId));
      publish(const StudentsChanged());
      await refreshHistory();
    } on AppException catch (e) {
      _periodUploadStatus = UploadStatus.error;
      _periodUploadError = e;
    }
    notifyListeners();
  }

  void resetPeriodUpload() {
    _periodUploadStatus = UploadStatus.idle;
    _periodLastResult = null;
    _periodUploadError = null;
    notifyListeners();
  }

  Future<BinaryDownload> downloadSchoolSetupTemplate() =>
      _repository.downloadSchoolSetupTemplate();

  Future<void> uploadSchoolSetup({
    required String fileName,
    required List<int> bytes,
  }) async {
    _schoolSetupUploadStatus = UploadStatus.uploading;
    _schoolSetupUploadError = null;
    _schoolSetupLastResult = null;
    notifyListeners();
    try {
      _schoolSetupLastResult = await _repository.uploadSchoolSetup(
        fileName: fileName,
        bytes: bytes,
      );
      _schoolSetupUploadStatus = UploadStatus.done;
      // Periods, levels, subjects, courses, classes, students, grades and
      // attendance may all have changed.
      publish(const SessionDataReset());
      await refreshHistory();
    } on AppException catch (e) {
      _schoolSetupUploadStatus = UploadStatus.error;
      _schoolSetupUploadError = e;
    }
    notifyListeners();
  }

  void resetSchoolSetupUpload() {
    _schoolSetupUploadStatus = UploadStatus.idle;
    _schoolSetupLastResult = null;
    _schoolSetupUploadError = null;
    notifyListeners();
  }
}
