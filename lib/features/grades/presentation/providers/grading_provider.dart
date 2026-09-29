import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/detail_state.dart';
import '../../data/repositories/grading_repository.dart';
import '../../domain/entities/grading_entities.dart';

class GradingProvider extends ChangeNotifier {
  GradingProvider(this._repository);

  final GradingRepository _repository;

  List<GradingScaleEntity> _scales = [];
  List<GradingScaleEntity> get scales => _scales;

  List<EvaluationCategoryEntity> _categories = [];
  List<EvaluationCategoryEntity> get categories => _categories;

  DetailViewState<GradingConfigurationEntity?> _configState = const DetailViewState();
  DetailViewState<GradingConfigurationEntity?> get configState => _configState;

  DetailViewState<PeriodGradesEntity> _periodGradesState = const DetailViewState();
  DetailViewState<PeriodGradesEntity> get periodGradesState => _periodGradesState;

  Future<void> loadCatalog() async {
    try {
      final results = await Future.wait([_repository.getScales(), _repository.getCategories()]);
      _scales = results[0] as List<GradingScaleEntity>;
      _categories = results[1] as List<EvaluationCategoryEntity>;
      notifyListeners();
    } on AppException {
      // Surfaced implicitly: dependent screens show their own empty state
      // when scales/categories end up empty.
    }
  }

  Future<AppException?> createScale({
    required String name,
    required double minimumValue,
    required double maximumValue,
  }) async {
    try {
      await _repository.createScale(name: name, minimumValue: minimumValue, maximumValue: maximumValue);
      await loadCatalog();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<void> loadConfiguration(int teachingPeriodId) async {
    _configState = DetailViewState.loading();
    notifyListeners();
    try {
      final config = await _repository.getConfiguration(teachingPeriodId);
      _configState = DetailViewState.success(config);
    } on AppException catch (e) {
      _configState = DetailViewState.error(e);
    }
    notifyListeners();
  }

  Future<AppException?> saveConfiguration(
    int teachingPeriodId, {
    required int gradingScaleId,
    required List<CategoryWeight> weights,
  }) async {
    try {
      final config = await _repository.putConfiguration(
        teachingPeriodId,
        gradingScaleId: gradingScaleId,
        weights: weights,
      );
      _configState = DetailViewState.success(config);
      notifyListeners();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  /// One class's period grades without touching [periodGradesState], for
  /// screens that read several classes at once (e.g. a student's grades).
  /// Throws [AppException].
  Future<PeriodGradesEntity> fetchPeriodGrades(int teachingPeriodId) =>
      _repository.getPeriodGrades(teachingPeriodId);

  Future<void> loadPeriodGrades(int teachingPeriodId) async {
    _periodGradesState = DetailViewState.loading();
    notifyListeners();
    try {
      final grades = await _repository.getPeriodGrades(teachingPeriodId);
      _periodGradesState = DetailViewState.success(grades);
    } on AppException catch (e) {
      _periodGradesState = DetailViewState.error(e);
    }
    notifyListeners();
  }
}
