import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/academic_level_entity.dart';
import '../models/academic_level_model.dart';

class AcademicLevelRemoteDataSource {
  AcademicLevelRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<AcademicLevelEntity>> getAll() async {
    final response = await _client.get(ApiEndpoints.grades);
    return (response.data as List<dynamic>)
        .map((e) => AcademicLevelModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AcademicLevelEntity> create({required String name, String? description}) async {
    final response = await _client.post(
      ApiEndpoints.grades,
      data: AcademicLevelModel.toRequest(name: name, description: description),
    );
    return AcademicLevelModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AcademicLevelEntity> update(
    int id, {
    required String name,
    String? description,
  }) async {
    final response = await _client.put(
      ApiEndpoints.gradeById(id),
      data: AcademicLevelModel.toRequest(name: name, description: description),
    );
    return AcademicLevelModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete(ApiEndpoints.gradeById(id));
}
