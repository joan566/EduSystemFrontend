import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/downloads.dart';
import '../../data/repositories/import_repository.dart';
import '../../domain/entities/import_batch_entity.dart';

enum UploadStatus { idle, uploading, done, error }

class ImportsProvider extends ChangeNotifier {
  ImportsProvider(this._repository);

  final ImportRepository _repository;

  ListViewState<ImportBatchEntity> _historyState = const ListViewState();
  ListViewState<ImportBatchEntity> get historyState => _historyState;

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

  Future<void> loadHistory({int page = 0}) async {
    _historyState = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _repository.getHistory(page: page);
      _historyState = ListViewState.fromPage(
        content: result.content,
        page: result.page,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
      );
    } on AppException catch (e) {
      _historyState = ListViewState.error(e);
    }
    notifyListeners();
  }

  Future<void> downloadTemplate() async {
    final download = await _repository.downloadTemplate();
    await Downloads.save(download);
  }

  Future<void> downloadErrorReport(int importId) async {
    final download = await _repository.downloadErrorReport(importId);
    await Downloads.save(download);
  }

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
      await loadHistory();
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
      await loadHistory();
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

  Future<void> downloadSchoolSetupTemplate() async {
    final download = await _repository.downloadSchoolSetupTemplate();
    await Downloads.save(download);
  }

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
      await loadHistory();
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
