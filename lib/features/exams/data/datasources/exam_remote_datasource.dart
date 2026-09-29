import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/submission_batch_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../models/exam_models.dart';
import '../models/submission_batch_models.dart';
import '../models/submission_models.dart';

class ExamRemoteDataSource {
  ExamRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ExamEntity> create({
    required int teachingPeriodId,
    required String name,
    String? description,
    DateTime? evaluationDate,
    double? maximumScore,
    required int numberOfQuestions,
  }) async {
    final response = await _client.post(
      ApiEndpoints.exams,
      data: ExamModel.toCreateRequest(
        teachingPeriodId: teachingPeriodId,
        name: name,
        description: description,
        evaluationDate: evaluationDate,
        maximumScore: maximumScore,
        numberOfQuestions: numberOfQuestions,
      ),
    );
    return ExamModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiPage<ExamSummaryEntity>> getPage({
    required int teachingPeriodId,
    int page = 0,
  }) async {
    final response = await _client.get(
      ApiEndpoints.exams,
      queryParameters: {
        'teachingPeriodId': teachingPeriodId,
        'page': page,
        'size': 20,
      },
    );
    return ApiPage.fromJson(
      response.data as Map<String, dynamic>,
      ExamSummaryModel.fromJson,
    );
  }

  Future<ExamEntity> getById(int examId) async {
    final response = await _client.get(ApiEndpoints.examById(examId));
    return ExamModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExamEntity> update(
    int examId, {
    required String name,
    String? description,
    DateTime? evaluationDate,
  }) async {
    final response = await _client.put(
      ApiEndpoints.examById(examId),
      data: ExamModel.toUpdateRequest(
        name: name,
        description: description,
        evaluationDate: evaluationDate,
      ),
    );
    return ExamModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExamEntity> replaceQuestions(
    int examId,
    List<ExamQuestion> questions,
  ) async {
    final response = await _client.put(
      ApiEndpoints.examQuestions(examId),
      data: {'questions': questions.map(ExamQuestionModel.toJson).toList()},
    );
    return ExamModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int examId) =>
      _client.delete(ApiEndpoints.examById(examId));

  Future<BinaryDownload> getAnswerSheet(int examId, int studentId) =>
      _client.getBinary(ApiEndpoints.answerSheet(examId, studentId));

  Future<BinaryDownload> getAnswerSheets(int examId) =>
      _client.getBinary(ApiEndpoints.answerSheets(examId));

  Future<SubmissionEntity> uploadSubmission(
    int examId, {
    required List<int> imageBytes,
    required String fileName,
    int? studentId,
    bool replace = false,
  }) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(imageBytes, filename: fileName),
    });
    final response = await _client.postMultipart(
      ApiEndpoints.submissions(examId),
      formData: formData,
      queryParameters: {'studentId': studentId, 'replace': replace},
    );
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Uploads a PDF with every scanned sheet. The backend answers 202 right
  /// away with the queued batch; grading happens in the background.
  Future<SubmissionBatchSummaryEntity> uploadSubmissionBatch(
    int examId, {
    required List<int> pdfBytes,
    required String fileName,
    bool replace = false,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        pdfBytes,
        filename: fileName,
        contentType: MediaType('application', 'pdf'),
      ),
    });
    final response = await _client.postMultipart(
      ApiEndpoints.submissionBatches(examId),
      formData: formData,
      queryParameters: {'replace': replace},
      onSendProgress: onSendProgress,
    );
    return SubmissionBatchSummaryModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<SubmissionBatchSummaryEntity>> getSubmissionBatches(
    int examId,
  ) async {
    final response = await _client.get(ApiEndpoints.submissionBatches(examId));
    return (response.data as List<dynamic>)
        .map(
          (e) =>
              SubmissionBatchSummaryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<SubmissionBatchEntity> getSubmissionBatch(
    int examId,
    int batchId,
  ) async {
    final response = await _client.get(
      ApiEndpoints.submissionBatchById(examId, batchId),
    );
    return SubmissionBatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiPage<SubmissionSummaryEntity>> getSubmissions(
    int examId, {
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    final response = await _client.get(
      ApiEndpoints.submissions(examId),
      queryParameters: {'page': page, 'size': size, 'status': status},
    );
    return ApiPage.fromJson(
      response.data as Map<String, dynamic>,
      SubmissionSummaryModel.fromJson,
    );
  }

  Future<SubmissionEntity> getSubmission(int examId, int submissionId) async {
    final response = await _client.get(
      ApiEndpoints.submissionById(examId, submissionId),
    );
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<int>> getSubmissionImage(int examId, int submissionId) =>
      _client.getImageBytes(ApiEndpoints.submissionImage(examId, submissionId));

  Future<SubmissionEntity> correctAnswer(
    int examId,
    int submissionId,
    int questionNumber, {
    String? selectedOption,
    String? reason,
  }) async {
    final response = await _client.put(
      ApiEndpoints.submissionAnswer(examId, submissionId, questionNumber),
      data: {'selectedOption': selectedOption, 'reason': reason},
    );
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubmissionEntity> setFinalGrade(
    int examId,
    int submissionId, {
    required double finalGrade,
    String? reason,
  }) async {
    final response = await _client.put(
      ApiEndpoints.submissionFinalGrade(examId, submissionId),
      data: {'finalGrade': finalGrade, 'reason': reason},
    );
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }
}
