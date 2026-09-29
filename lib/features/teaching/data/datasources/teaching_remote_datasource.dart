import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../../domain/entities/teaching_period_summary_entity.dart';
import '../models/teaching_models.dart';

class TeachingRemoteDataSource {
  TeachingRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ApiPage<TeachingAssignmentEntity>> getAssignments({
    int page = 0,
    int? groupId,
    int? subjectId,
    bool? active,
  }) async {
    final response = await _client.get(
      ApiEndpoints.teachingAssignments,
      queryParameters: {
        'page': page,
        'size': 20,
        'groupId': groupId,
        'subjectId': subjectId,
        'active': active,
      },
    );
    return ApiPage.fromJson(
      response.data as Map<String, dynamic>,
      TeachingAssignmentModel.fromJson,
    );
  }

  Future<TeachingAssignmentEntity> createAssignment({
    required int groupId,
    required int subjectId,
  }) async {
    final response = await _client.post(
      ApiEndpoints.teachingAssignments,
      data: {'groupId': groupId, 'subjectId': subjectId},
    );
    return TeachingAssignmentModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> setAssignmentActive(int id, bool active) => _client.patch(
    ApiEndpoints.teachingAssignmentActive(id),
    data: {'active': active},
  );

  Future<void> deleteAssignment(int id) =>
      _client.delete(ApiEndpoints.teachingAssignmentById(id));

  Future<ApiPage<TeachingPeriodEntity>> getPeriods({
    int page = 0,
    int? teachingAssignmentId,
    int? academicPeriodId,
  }) async {
    final response = await _client.get(
      ApiEndpoints.teachingPeriods,
      queryParameters: {
        'page': page,
        'size': 20,
        'teachingAssignmentId': teachingAssignmentId,
        'academicPeriodId': academicPeriodId,
      },
    );
    return ApiPage.fromJson(
      response.data as Map<String, dynamic>,
      TeachingPeriodModel.fromJson,
    );
  }

  Future<TeachingPeriodEntity> createPeriod({
    required int teachingAssignmentId,
    required int academicPeriodId,
  }) async {
    final response = await _client.post(
      ApiEndpoints.teachingPeriods,
      data: {
        'teachingAssignmentId': teachingAssignmentId,
        'academicPeriodId': academicPeriodId,
      },
    );
    return TeachingPeriodModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeachingPeriodEntity> getPeriod(int id) async {
    final response = await _client.get(ApiEndpoints.teachingPeriodById(id));
    return TeachingPeriodModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeachingPeriodSummaryEntity> getPeriodSummary(int id) async {
    final response = await _client.get(ApiEndpoints.teachingPeriodSummary(id));
    return TeachingPeriodSummaryModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deletePeriod(int id) =>
      _client.delete(ApiEndpoints.teachingPeriodById(id));
}
