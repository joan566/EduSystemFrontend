import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/course_entity.dart';
import '../models/course_model.dart';

class CourseRemoteDataSource {
  CourseRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ApiPage<CourseEntity>> getPage({
    int page = 0,
    int size = 20,
    int? gradeId,
    int? academicYear,
  }) async {
    final response = await _client.get(
      ApiEndpoints.groups,
      queryParameters: {
        'page': page,
        'size': size,
        'gradeId': gradeId,
        'academicYear': academicYear,
      },
    );
    return ApiPage.fromJson(
      response.data as Map<String, dynamic>,
      CourseModel.fromJson,
    );
  }

  Future<CourseEntity> create({
    required int gradeId,
    required String name,
    required int academicYear,
  }) async {
    final response = await _client.post(
      ApiEndpoints.groups,
      data: CourseModel.toCreateRequest(
        gradeId: gradeId,
        name: name,
        academicYear: academicYear,
      ),
    );
    return CourseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CourseEntity> update(
    int id, {
    required String name,
    required int academicYear,
  }) async {
    final response = await _client.put(
      ApiEndpoints.groupById(id),
      data: CourseModel.toUpdateRequest(name: name, academicYear: academicYear),
    );
    return CourseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete(ApiEndpoints.groupById(id));
}
