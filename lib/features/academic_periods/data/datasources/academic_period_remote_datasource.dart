import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/academic_period_entity.dart';
import '../models/academic_period_model.dart';

class AcademicPeriodRemoteDataSource {
  AcademicPeriodRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ApiPage<AcademicPeriodEntity>> getPage({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.academicPeriods,
      queryParameters: {'page': page, 'size': size},
    );
    return ApiPage.fromJson(
      response.data as Map<String, dynamic>,
      AcademicPeriodModel.fromJson,
    );
  }

  Future<AcademicPeriodEntity> create({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client.post(
      ApiEndpoints.academicPeriods,
      data: AcademicPeriodModel.toRequest(
        name: name,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    return AcademicPeriodModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AcademicPeriodEntity> update(
    int id, {
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client.put(
      ApiEndpoints.academicPeriodById(id),
      data: AcademicPeriodModel.toRequest(
        name: name,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    return AcademicPeriodModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) =>
      _client.delete(ApiEndpoints.academicPeriodById(id));
}
