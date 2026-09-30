import 'package:dio/dio.dart';

import '../../../../core/cache/paging.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/submission_batch_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../datasources/exam_remote_datasource.dart';

class ExamRepository {
  ExamRepository(this._remote);

  final ExamRemoteDataSource _remote;

  Future<ExamEntity> create({
    required int teachingPeriodId,
    required String name,
    String? description,
    DateTime? evaluationDate,
    double? maximumScore,
    required int numberOfQuestions,
  }) => _remote.create(
    teachingPeriodId: teachingPeriodId,
    name: name,
    description: description,
    evaluationDate: evaluationDate,
    maximumScore: maximumScore,
    numberOfQuestions: numberOfQuestions,
  );

  /// Every exam of one class (all pages).
  Future<List<ExamSummaryEntity>> getAll(int teachingPeriodId) => fetchAllPages(
    (page, size) => _remote.getPage(
      teachingPeriodId: teachingPeriodId,
      page: page,
      size: size,
    ),
  );

  Future<ExamEntity> getById(int examId) => _remote.getById(examId);

  Future<ExamEntity> update(
    int examId, {
    required String name,
    String? description,
    DateTime? evaluationDate,
  }) => _remote.update(
    examId,
    name: name,
    description: description,
    evaluationDate: evaluationDate,
  );

  Future<ExamEntity> replaceQuestions(
    int examId,
    List<ExamQuestion> questions,
  ) => _remote.replaceQuestions(examId, questions);

  Future<void> delete(int examId) => _remote.delete(examId);

  Future<BinaryDownload> getAnswerSheet(int examId, int studentId) =>
      _remote.getAnswerSheet(examId, studentId);

  Future<BinaryDownload> getAnswerSheets(int examId) =>
      _remote.getAnswerSheets(examId);

  Future<SubmissionEntity> uploadSubmission(
    int examId, {
    required List<int> imageBytes,
    required String fileName,
    int? studentId,
    bool replace = false,
  }) => _remote.uploadSubmission(
    examId,
    imageBytes: imageBytes,
    fileName: fileName,
    studentId: studentId,
    replace: replace,
  );

  Future<SubmissionBatchSummaryEntity> uploadSubmissionBatch(
    int examId, {
    required List<int> pdfBytes,
    required String fileName,
    bool replace = false,
    ProgressCallback? onSendProgress,
  }) => _remote.uploadSubmissionBatch(
    examId,
    pdfBytes: pdfBytes,
    fileName: fileName,
    replace: replace,
    onSendProgress: onSendProgress,
  );

  Future<List<SubmissionBatchSummaryEntity>> getSubmissionBatches(int examId) =>
      _remote.getSubmissionBatches(examId);

  Future<SubmissionBatchEntity> getSubmissionBatch(int examId, int batchId) =>
      _remote.getSubmissionBatch(examId, batchId);

  Future<ApiPage<SubmissionSummaryEntity>> getSubmissions(
    int examId, {
    int page = 0,
    int size = 20,
    String? status,
  }) => _remote.getSubmissions(examId, page: page, size: size, status: status);

  /// Every submission of an exam (all pages; a class fits in one).
  Future<List<SubmissionSummaryEntity>> getAllSubmissions(int examId) =>
      fetchAllPages(
        (page, size) => _remote.getSubmissions(examId, page: page, size: size),
      );

  Future<SubmissionEntity> getSubmission(int examId, int submissionId) =>
      _remote.getSubmission(examId, submissionId);

  Future<List<int>> getSubmissionImage(int examId, int submissionId) =>
      _remote.getSubmissionImage(examId, submissionId);

  Future<SubmissionEntity> correctAnswer(
    int examId,
    int submissionId,
    int questionNumber, {
    String? selectedOption,
    String? reason,
  }) => _remote.correctAnswer(
    examId,
    submissionId,
    questionNumber,
    selectedOption: selectedOption,
    reason: reason,
  );

  Future<SubmissionEntity> setFinalGrade(
    int examId,
    int submissionId, {
    required double finalGrade,
    String? reason,
  }) => _remote.setFinalGrade(
    examId,
    submissionId,
    finalGrade: finalGrade,
    reason: reason,
  );
}
