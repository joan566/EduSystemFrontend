import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/entities/submission_entity.dart';

enum UploadState { idle, uploading, done, error }

/// Owns submission listing, review/detail, correction and upload for a
/// single exam (§46-51). Scoped per exam like [ExamsProvider]'s detail
/// state, since a submission always belongs to exactly one exam.
class SubmissionsProvider extends ChangeNotifier {
  SubmissionsProvider(this._repository);

  final ExamRepository _repository;

  ListViewState<SubmissionSummaryEntity> _state = const ListViewState();
  ListViewState<SubmissionSummaryEntity> get state => _state;

  DetailViewState<SubmissionEntity> _detailState = const DetailViewState();
  DetailViewState<SubmissionEntity> get detailState => _detailState;

  UploadState _uploadState = UploadState.idle;
  UploadState get uploadState => _uploadState;
  AppException? _uploadError;
  AppException? get uploadError => _uploadError;
  SubmissionEntity? _lastUploaded;
  SubmissionEntity? get lastUploaded => _lastUploaded;

  // Remembered so a reload without [size] (e.g. back from batch grading)
  // keeps the page size the current view asked for.
  int _pageSize = 20;

  /// Exam the listing [state] belongs to. Views that switch exams quickly
  /// (the desktop list preview) check it before showing the numbers.
  int? _examId;
  int? get examId => _examId;

  // Only the latest request may write [state]; an older response arriving
  // late would otherwise show another exam's sheets.
  int _request = 0;

  Future<void> load(
    int examId, {
    int page = 0,
    int? size,
    String? status,
  }) async {
    _pageSize = size ?? _pageSize;
    _examId = examId;
    final request = ++_request;
    _state = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _repository.getSubmissions(
        examId,
        page: page,
        size: _pageSize,
        status: status,
      );
      if (request != _request) return;
      _state = ListViewState.fromPage(
        content: result.content,
        page: result.page,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
      );
    } on AppException catch (e) {
      if (request != _request) return;
      _state = ListViewState.error(e);
    }
    notifyListeners();
  }

  Future<List<int>> getImage(int examId, int submissionId) =>
      _repository.getSubmissionImage(examId, submissionId);

  Future<void> loadDetail(int examId, int submissionId) async {
    _detailState = DetailViewState.loading();
    notifyListeners();
    try {
      final submission = await _repository.getSubmission(examId, submissionId);
      _detailState = DetailViewState.success(submission);
    } on AppException catch (e) {
      _detailState = DetailViewState.error(e);
    }
    notifyListeners();
  }

  Future<void> upload(
    int examId, {
    required List<int> imageBytes,
    required String fileName,
    int? studentId,
    bool replace = false,
  }) async {
    _uploadState = UploadState.uploading;
    _uploadError = null;
    notifyListeners();
    try {
      final submission = await _repository.uploadSubmission(
        examId,
        imageBytes: imageBytes,
        fileName: fileName,
        studentId: studentId,
        replace: replace,
      );
      _lastUploaded = submission;
      _uploadState = UploadState.done;
    } on AppException catch (e) {
      _uploadState = UploadState.error;
      _uploadError = e;
    }
    notifyListeners();
  }

  void resetUpload() {
    _uploadState = UploadState.idle;
    _uploadError = null;
    _lastUploaded = null;
    notifyListeners();
  }

  Future<AppException?> correctAnswer(
    int examId,
    int submissionId,
    int questionNumber, {
    String? selectedOption,
    String? reason,
  }) async {
    try {
      final submission = await _repository.correctAnswer(
        examId,
        submissionId,
        questionNumber,
        selectedOption: selectedOption,
        reason: reason,
      );
      _detailState = DetailViewState.success(submission);
      notifyListeners();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> setFinalGrade(
    int examId,
    int submissionId, {
    required double finalGrade,
    String? reason,
  }) async {
    try {
      final submission = await _repository.setFinalGrade(
        examId,
        submissionId,
        finalGrade: finalGrade,
        reason: reason,
      );
      _detailState = DetailViewState.success(submission);
      notifyListeners();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
