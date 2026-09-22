import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/activity_entity.dart';
import '../models/activity_models.dart';

class ActivityRemoteDataSource {
  ActivityRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ActivityEntity> create({
    required int teachingPeriodId,
    required String name,
    String? description,
    DateTime? evaluationDate,
    required double maximumScore,
    String? activityType,
  }) async {
    final response = await _client.post(
      ApiEndpoints.activities,
      data: ActivityModel.toCreateRequest(
        teachingPeriodId: teachingPeriodId,
        name: name,
        description: description,
        evaluationDate: evaluationDate,
        maximumScore: maximumScore,
        activityType: activityType,
      ),
    );
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiPage<ActivityEntity>> getPage({required int teachingPeriodId, int page = 0}) async {
    final response = await _client.get(
      ApiEndpoints.activities,
      queryParameters: {'teachingPeriodId': teachingPeriodId, 'page': page, 'size': 20},
    );
    return ApiPage.fromJson(response.data as Map<String, dynamic>, ActivityModel.fromJson);
  }

  Future<ActivityEntity> getById(int id) async {
    final response = await _client.get(ApiEndpoints.activityById(id));
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityEntity> update(
    int id, {
    required String name,
    String? description,
    DateTime? evaluationDate,
    double? maximumScore,
    String? activityType,
  }) async {
    final response = await _client.put(
      ApiEndpoints.activityById(id),
      data: ActivityModel.toUpdateRequest(
        name: name,
        description: description,
        evaluationDate: evaluationDate,
        maximumScore: maximumScore,
        activityType: activityType,
      ),
    );
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete(ApiEndpoints.activityById(id));

  Future<List<StudentGradeEntity>> getGrades(int id) async {
    final response = await _client.get(ApiEndpoints.activityGrades(id));
    return (response.data as List<dynamic>)
        .map((e) => StudentGradeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudentGradeEntity>> putGrades(
    int id,
    List<({int studentId, double grade, String? comment})> grades,
  ) async {
    final response = await _client.put(
      ApiEndpoints.activityGrades(id),
      data: {
        'grades': [
          for (final g in grades)
            {'studentId': g.studentId, 'grade': g.grade, if (g.comment != null) 'comment': g.comment},
        ],
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => StudentGradeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudentGradeEntity>> putStudentGrade(
    int id,
    int studentId, {
    required double grade,
    String? comment,
  }) async {
    final response = await _client.put(
      ApiEndpoints.activityStudentGrade(id, studentId),
      data: {'grade': grade, 'comment': comment},
    );
    return (response.data as List<dynamic>)
        .map((e) => StudentGradeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
