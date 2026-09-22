import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/grading_entities.dart';
import '../models/grading_models.dart';

class GradingRemoteDataSource {
  GradingRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<GradingScaleEntity>> getScales() async {
    final response = await _client.get(ApiEndpoints.gradingScales);
    return (response.data as List<dynamic>)
        .map((e) => GradingScaleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GradingScaleEntity> createScale({
    required String name,
    required double minimumValue,
    required double maximumValue,
  }) async {
    final response = await _client.post(
      ApiEndpoints.gradingScales,
      data: {'name': name, 'minimumValue': minimumValue, 'maximumValue': maximumValue},
    );
    return GradingScaleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<EvaluationCategoryEntity>> getCategories() async {
    final response = await _client.get(ApiEndpoints.evaluationCategories);
    return (response.data as List<dynamic>)
        .map((e) => EvaluationCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GradingConfigurationEntity?> getConfiguration(int teachingPeriodId) async {
    try {
      final response = await _client.get(ApiEndpoints.gradingConfiguration(teachingPeriodId));
      return GradingConfigurationModel.fromJson(response.data as Map<String, dynamic>);
    } on AppException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  Future<GradingConfigurationEntity> putConfiguration(
    int teachingPeriodId, {
    required int gradingScaleId,
    required List<CategoryWeight> weights,
  }) async {
    final response = await _client.put(
      ApiEndpoints.gradingConfiguration(teachingPeriodId),
      data: {
        'gradingScaleId': gradingScaleId,
        'weights': [
          for (final w in weights)
            {'evaluationCategoryId': w.evaluationCategoryId, 'weight': w.weight},
        ],
      },
    );
    return GradingConfigurationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PeriodGradesEntity> getPeriodGrades(int teachingPeriodId) async {
    final response = await _client.get(ApiEndpoints.periodGrades(teachingPeriodId));
    return PeriodGradesModel.fromJson(response.data as Map<String, dynamic>);
  }
}
