import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../models/gradebook_models.dart';

/// A student's grades evaluation by evaluation: report, grade detail,
/// rubrics, attachments and the teacher's observation.
class GradebookRemoteDataSource {
  GradebookRemoteDataSource(this._client);

  final ApiClient _client;

  Future<StudentGradeReport> getReport(
    int teachingPeriodId,
    int studentId,
  ) async {
    final response = await _client.get(
      ApiEndpoints.studentGradeReport(teachingPeriodId, studentId),
    );
    return GradebookModels.report(response.data as Map<String, dynamic>);
  }

  Future<GradeDetailEntity> getDetail(int evaluationId, int studentId) async {
    final response = await _client.get(
      ApiEndpoints.gradeDetail(evaluationId, studentId),
    );
    return GradebookModels.detail(response.data as Map<String, dynamic>);
  }

  /// Returns null when [text] is blank (the observation was removed).
  Future<StudentObservationEntity?> saveObservation(
    int teachingPeriodId,
    int studentId,
    String text,
  ) async {
    final response = await _client.put(
      ApiEndpoints.studentObservation(teachingPeriodId, studentId),
      data: {'text': text},
    );
    return GradebookModels.observation(response.data);
  }

  Future<void> saveRubric(
    int evaluationId,
    List<RubricCriterionInput> criteria,
  ) => _client.put(
    ApiEndpoints.evaluationRubric(evaluationId),
    data: {
      'criteria': [
        for (final c in criteria)
          {'id': c.id, 'name': c.name, 'weight': c.weight},
      ],
    },
  );

  Future<void> deleteRubric(int evaluationId) =>
      _client.delete(ApiEndpoints.evaluationRubric(evaluationId));

  Future<GradeDetailEntity> scoreWithRubric(
    int evaluationId,
    int studentId, {
    required Map<int, double> scores,
    String? comment,
  }) async {
    final response = await _client.put(
      ApiEndpoints.rubricScores(evaluationId, studentId),
      data: {
        'scores': [
          for (final e in scores.entries)
            {'criterionId': e.key, 'score': e.value},
        ],
        'comment': comment,
      },
    );
    return GradebookModels.detail(response.data as Map<String, dynamic>);
  }

  /// Records an activity grade by hand (without the rubric).
  Future<void> saveActivityGrade(
    int activityId,
    int studentId, {
    required double grade,
    String? comment,
  }) => _client.put(
    ApiEndpoints.activityStudentGrade(activityId, studentId),
    data: {'grade': grade, 'comment': comment},
  );

  Future<void> uploadAttachment(
    int evaluationId,
    int studentId, {
    required List<int> bytes,
    required String fileName,
  }) => _client.postMultipart(
    ApiEndpoints.gradeAttachment(evaluationId, studentId),
    formData: FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    }),
  );

  Future<BinaryDownload> downloadAttachment(int evaluationId, int studentId) =>
      _client.getBinary(ApiEndpoints.gradeAttachment(evaluationId, studentId));

  Future<void> deleteAttachment(int evaluationId, int studentId) =>
      _client.delete(ApiEndpoints.gradeAttachment(evaluationId, studentId));

  /// A class's evaluations (all pages: a class has few dozen at most).
  Future<List<EvaluationSummaryEntity>> getEvaluations(
    int teachingPeriodId,
  ) async {
    final response = await _client.get(
      ApiEndpoints.evaluations,
      queryParameters: {'teachingPeriodId': teachingPeriodId, 'size': 100},
    );
    return [
      for (final e
          in (response.data as Map<String, dynamic>)['content']
              as List<dynamic>)
        GradebookModels.evaluation(e as Map<String, dynamic>),
    ];
  }
}
