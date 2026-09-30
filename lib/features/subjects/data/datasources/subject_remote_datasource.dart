import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/subject_entity.dart';
import '../models/subject_model.dart';

class SubjectRemoteDataSource {
  SubjectRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ApiPage<SubjectEntity>> getPage({
    int page = 0,
    int size = 20,
    String? name,
  }) async {
    final response = await _client.get(
      ApiEndpoints.subjects,
      queryParameters: {'page': page, 'size': size, 'name': name},
    );
    return ApiPage.fromJson(
      response.data as Map<String, dynamic>,
      SubjectModel.fromJson,
    );
  }

  Future<SubjectEntity> create({
    required String name,
    String? description,
  }) async {
    final response = await _client.post(
      ApiEndpoints.subjects,
      data: SubjectModel.toRequest(name: name, description: description),
    );
    return SubjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubjectEntity> update(
    int id, {
    required String name,
    String? description,
  }) async {
    final response = await _client.put(
      ApiEndpoints.subjectById(id),
      data: SubjectModel.toRequest(name: name, description: description),
    );
    return SubjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete(ApiEndpoints.subjectById(id));
}
