import '../../../../core/cache/keyed_cache.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/entities/submission_entity.dart';

enum UploadState { idle, uploading, done, error }

/// Submissions (§46-51): each exam's results (`examId → its submissions`),
/// each submission's review (`(examId, submissionId) → detail`), its
/// scanned image (a few, recently viewed) and the single-sheet upload.
///
/// Corrections answer with the updated submission, which is written into
/// the review and into its exam's results; uploads and batch grading make
/// the exam's results stale ([ExamResultsChanged]).
class SubmissionsProvider extends SessionNotifier {
  SubmissionsProvider(this._repository, DomainEvents events) : super(events);

  final ExamRepository _repository;

  late final _results = keyedCache<int, List<SubmissionSummaryEntity>>(
    maxEntries: 20,
  );

  late final _details = keyedCache<(int, int), SubmissionEntity>(
    maxEntries: 30,
  );

  /// Scanned sheets are reviewed back and forth; the last few are kept so
  /// reopening one doesn't download it again. Small on purpose.
  late final _images = keyedCache<(int, int), List<int>>(maxEntries: 6);

  // --- Results per exam ----------------------------------------------------

  ListViewState<SubmissionSummaryEntity> results(int examId) =>
      _results.view(examId);

  Future<void> ensureResults(int examId) =>
      _results.ensure(examId, () => _repository.getAllSubmissions(examId));

  Future<void> refreshResults(int examId) =>
      _results.refresh(examId, () => _repository.getAllSubmissions(examId));

  // --- One submission ------------------------------------------------------

  DetailViewState<SubmissionEntity> detail(int examId, int submissionId) =>
      _details.detailView((examId, submissionId));

  Future<void> ensureDetail(int examId, int submissionId) => _details.ensure((
    examId,
    submissionId,
  ), () => _repository.getSubmission(examId, submissionId));

  Future<void> refreshDetail(int examId, int submissionId) => _details.refresh((
    examId,
    submissionId,
  ), () => _repository.getSubmission(examId, submissionId));

  /// The scanned sheet. Throws [AppException].
  Future<List<int>> getImage(int examId, int submissionId) async {
    final key = (examId, submissionId);
    await _images.ensure(
      key,
      () => _repository.getSubmissionImage(examId, submissionId),
    );
    final bytes = _images.dataOf(key);
    if (bytes != null) return bytes;
    throw _images.peek(key)?.error ??
        const AppException(
          code: AppErrorCode.unknown,
          message: 'An unexpected error occurred.',
        );
  }

  // --- Single-sheet upload (scanning) --------------------------------------

  UploadState _uploadState = UploadState.idle;
  UploadState get uploadState => _uploadState;
  AppException? _uploadError;
  AppException? get uploadError => _uploadError;
  SubmissionEntity? _lastUploaded;
  SubmissionEntity? get lastUploaded => _lastUploaded;

  Future<void> upload(
    int examId, {
    required List<int> imageBytes,
    required String fileName,
    int? studentId,
    bool replace = false,
    int? teachingPeriodId,
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
      _announce(examId, teachingPeriodId);
      _details.set((examId, submission.id), submission);
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

  // --- Corrections ---------------------------------------------------------

  Future<AppException?> correctAnswer(
    int examId,
    int submissionId,
    int questionNumber, {
    String? selectedOption,
    String? reason,
    int? teachingPeriodId,
  }) => _correct(
    examId,
    teachingPeriodId,
    () => _repository.correctAnswer(
      examId,
      submissionId,
      questionNumber,
      selectedOption: selectedOption,
      reason: reason,
    ),
  );

  Future<AppException?> setFinalGrade(
    int examId,
    int submissionId, {
    required double finalGrade,
    String? reason,
    int? teachingPeriodId,
  }) => _correct(
    examId,
    teachingPeriodId,
    () => _repository.setFinalGrade(
      examId,
      submissionId,
      finalGrade: finalGrade,
      reason: reason,
    ),
  );

  /// Writes the corrected submission into its review and its exam's
  /// results row; the class's grades go stale.
  Future<AppException?> _correct(
    int examId,
    int? teachingPeriodId,
    Future<SubmissionEntity> Function() request,
  ) async {
    try {
      final submission = await request();
      _announce(examId, teachingPeriodId, newSheets: false);
      _details.set((examId, submission.id), submission);
      _results.update(
        examId,
        (rows) => [
          for (final row in rows)
            row.id == submission.id ? _rowOf(submission) : row,
        ],
      );
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  static SubmissionSummaryEntity _rowOf(SubmissionEntity s) =>
      SubmissionSummaryEntity(
        id: s.id,
        studentId: s.student.id,
        studentCode: s.student.studentCode,
        studentName: s.student.name,
        status: s.status,
        score: s.score,
        finalGrade: s.finalGrade,
        statusDetail: s.statusDetail,
        submittedAt: s.submittedAt,
        processedAt: s.processedAt,
      );

  void _announce(int examId, int? teachingPeriodId, {bool newSheets = true}) {
    publish(
      ExamResultsChanged(
        examId,
        teachingPeriodId: teachingPeriodId,
        newSheets: newSheets,
      ),
    );
    if (teachingPeriodId != null) {
      publish(ClassDataChanged(teachingPeriodId, const {ClassAspect.grades}));
    }
  }

  @override
  void onDomainEvent(DomainEvent event) {
    switch (event) {
      case ExamResultsChanged(:final examId, newSheets: true):
        // A sheet was added or regraded: rows, reviews and images may be
        // new.
        _results.invalidate(examId);
        _details.invalidateWhere((key, _) => key.$1 == examId);
        _images.removeWhere((key, _) => key.$1 == examId);
      case StudentsChanged():
        _results.invalidateAll();
      default:
        break;
    }
  }
}
