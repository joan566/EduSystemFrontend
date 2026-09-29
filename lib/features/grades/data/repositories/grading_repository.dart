import '../../domain/entities/grading_entities.dart';
import '../datasources/grading_remote_datasource.dart';

class GradingRepository {
  GradingRepository(this._remote);

  final GradingRemoteDataSource _remote;

  Future<List<GradingScaleEntity>> getScales() => _remote.getScales();

  Future<GradingScaleEntity> createScale({
    required String name,
    required double minimumValue,
    required double maximumValue,
  }) => _remote.createScale(
    name: name,
    minimumValue: minimumValue,
    maximumValue: maximumValue,
  );

  Future<List<EvaluationCategoryEntity>> getCategories() =>
      _remote.getCategories();

  Future<GradingConfigurationEntity?> getConfiguration(int teachingPeriodId) =>
      _remote.getConfiguration(teachingPeriodId);

  Future<GradingConfigurationEntity> putConfiguration(
    int teachingPeriodId, {
    required int gradingScaleId,
    required List<CategoryWeight> weights,
    double? passingGrade,
  }) => _remote.putConfiguration(
    teachingPeriodId,
    gradingScaleId: gradingScaleId,
    weights: weights,
    passingGrade: passingGrade,
  );

  Future<PeriodGradesEntity> getPeriodGrades(int teachingPeriodId) =>
      _remote.getPeriodGrades(teachingPeriodId);
}
