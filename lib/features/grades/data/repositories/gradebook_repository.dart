import '../../../../core/network/api_client.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../datasources/gradebook_remote_datasource.dart';

class GradebookRepository {
  GradebookRepository(this._remote);

  final GradebookRemoteDataSource _remote;

  Future<StudentGradeReport> getReport(int teachingPeriodId, int studentId) =>
      _remote.getReport(teachingPeriodId, studentId);

  Future<GradeDetailEntity> getDetail(int evaluationId, int studentId) =>
      _remote.getDetail(evaluationId, studentId);

  Future<StudentObservationEntity?> saveObservation(
    int teachingPeriodId,
    int studentId,
    String text,
  ) => _remote.saveObservation(teachingPeriodId, studentId, text);

  Future<void> saveRubric(
    int evaluationId,
    List<RubricCriterionInput> criteria,
  ) => _remote.saveRubric(evaluationId, criteria);

  Future<void> deleteRubric(int evaluationId) =>
      _remote.deleteRubric(evaluationId);

  Future<GradeDetailEntity> scoreWithRubric(
    int evaluationId,
    int studentId, {
    required Map<int, double> scores,
    String? comment,
  }) => _remote.scoreWithRubric(
    evaluationId,
    studentId,
    scores: scores,
    comment: comment,
  );

  Future<void> saveActivityGrade(
    int activityId,
    int studentId, {
    required double grade,
    String? comment,
  }) => _remote.saveActivityGrade(
    activityId,
    studentId,
    grade: grade,
    comment: comment,
  );

  Future<void> uploadAttachment(
    int evaluationId,
    int studentId, {
    required List<int> bytes,
    required String fileName,
  }) => _remote.uploadAttachment(
    evaluationId,
    studentId,
    bytes: bytes,
    fileName: fileName,
  );

  Future<BinaryDownload> downloadAttachment(int evaluationId, int studentId) =>
      _remote.downloadAttachment(evaluationId, studentId);

  Future<void> deleteAttachment(int evaluationId, int studentId) =>
      _remote.deleteAttachment(evaluationId, studentId);

  Future<List<EvaluationSummaryEntity>> getEvaluations(int teachingPeriodId) =>
      _remote.getEvaluations(teachingPeriodId);
}
