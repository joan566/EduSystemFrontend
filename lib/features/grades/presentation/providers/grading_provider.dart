import '../../../../core/cache/catalog.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/detail_state.dart';
import '../../data/repositories/grading_repository.dart';
import '../../domain/entities/grading_entities.dart';

/// Grading catalogs (scales, evaluation categories — read once per
/// session) and, per class, its grading configuration and its period
/// grades.
///
/// A class's period grades are one response for every student of the
/// class: whoever needs one student's grade in that class (the Grades
/// screen, a student's detail, a preview) reads it from here, so it is
/// requested once per class, not once per student.
class GradingProvider extends SessionNotifier {
  GradingProvider(this._repository, DomainEvents events) : super(events);

  final GradingRepository _repository;

  late final Catalog<GradingScaleEntity> _scales = Catalog(
    cachedValue(),
    idOf: (s) => s.id,
    fetch: _repository.getScales,
    // The API lists them by id.
    compare: (a, b) => a.id.compareTo(b.id),
  );

  late final _categories = cachedValue<List<EvaluationCategoryEntity>>();

  /// Null data: the class has no configuration yet.
  late final _configurations = keyedCache<int, GradingConfigurationEntity?>();

  late final _periodGrades = keyedCache<int, PeriodGradesEntity>();

  /// What changes a class's computed grades.
  static const _gradeInputs = {
    ClassAspect.grades,
    ClassAspect.exams,
    ClassAspect.activities,
    ClassAspect.attendance,
    ClassAspect.configuration,
    ClassAspect.roster,
  };

  // --- Catalogs ------------------------------------------------------------

  List<GradingScaleEntity> get scales => _scales.items;
  List<EvaluationCategoryEntity> get categories => _categories.data ?? const [];

  /// Why the catalogs couldn't be read, if they couldn't.
  AppException? get catalogError =>
      _scales.view.error ?? _categories.detailView.error;

  Future<void> ensureCatalog() => Future.wait([
    _scales.ensure(),
    _categories.ensure(_repository.getCategories),
  ]);

  Future<void> refreshCatalog() => Future.wait([
    _scales.refresh(),
    _categories.refresh(_repository.getCategories),
  ]);

  Future<AppException?> createScale({
    required String name,
    required double minimumValue,
    required double maximumValue,
  }) async {
    try {
      _scales.upsert(
        await _repository.createScale(
          name: name,
          minimumValue: minimumValue,
          maximumValue: maximumValue,
        ),
      );
      publish(
        const CatalogChanged(
          CatalogResource.gradingScales,
          CatalogChange.created,
        ),
      );
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  // --- Configuration per class --------------------------------------------

  DetailViewState<GradingConfigurationEntity?> configuration(
    int teachingPeriodId,
  ) => _configurations.detailView(teachingPeriodId);

  Future<void> ensureConfiguration(int teachingPeriodId) =>
      _configurations.ensure(
        teachingPeriodId,
        () => _repository.getConfiguration(teachingPeriodId),
      );

  Future<void> refreshConfiguration(int teachingPeriodId) =>
      _configurations.refresh(
        teachingPeriodId,
        () => _repository.getConfiguration(teachingPeriodId),
      );

  Future<AppException?> saveConfiguration(
    int teachingPeriodId, {
    required int gradingScaleId,
    required List<CategoryWeight> weights,
    double? passingGrade,
  }) async {
    try {
      final config = await _repository.putConfiguration(
        teachingPeriodId,
        gradingScaleId: gradingScaleId,
        weights: weights,
        passingGrade: passingGrade,
      );
      _configurations.set(teachingPeriodId, config);
      publish(
        ClassDataChanged(teachingPeriodId, const {ClassAspect.configuration}),
      );
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  // --- Period grades per class --------------------------------------------

  DetailViewState<PeriodGradesEntity> periodGrades(int teachingPeriodId) =>
      _periodGrades.detailView(teachingPeriodId);

  Future<void> ensurePeriodGrades(int teachingPeriodId) => _periodGrades.ensure(
    teachingPeriodId,
    () => _repository.getPeriodGrades(teachingPeriodId),
  );

  Future<void> refreshPeriodGrades(int teachingPeriodId) =>
      _periodGrades.refresh(
        teachingPeriodId,
        () => _repository.getPeriodGrades(teachingPeriodId),
      );

  // --- Invalidation -------------------------------------------------------

  @override
  void onDomainEvent(DomainEvent event) {
    switch (event) {
      case ClassDataChanged(:final teachingPeriodId)
          when event.affects(_gradeInputs):
        _periodGrades.invalidate(teachingPeriodId);
      case StudentsChanged():
        // A student left or arrived: their classes' grades change.
        _periodGrades.invalidateAll();
      case ExamResultsChanged(teachingPeriodId: null):
        // The exam's class isn't known here: any class may have changed.
        _periodGrades.invalidateAll();
      default:
        break;
    }
  }
}
