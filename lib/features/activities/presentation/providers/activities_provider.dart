import '../../../../core/cache/cached_value.dart';
import '../../../../core/cache/keyed_cache.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/activity_repository.dart';
import '../../domain/entities/activity_entity.dart';

/// Activities per class (`teachingPeriodId → its activities`, every page),
/// each activity (read from its class's list when already there) and each
/// activity's grades.
class ActivitiesProvider extends SessionNotifier {
  ActivitiesProvider(this._repository, DomainEvents events) : super(events);

  final ActivityRepository _repository;

  late final _activities = keyedCache<int, List<ActivityEntity>>();

  /// Activities read one by one (opened before their class's list).
  late final _details = keyedCache<int, ActivityEntity>(maxEntries: 30);

  late final _grades = keyedCache<int, List<StudentGradeEntity>>(
    maxEntries: 30,
  );

  // --- Lists per class -----------------------------------------------------

  ListViewState<ActivityEntity> activities(int teachingPeriodId) =>
      _activities.view(teachingPeriodId);

  ListViewState<ActivityEntity> activitiesPage(
    int teachingPeriodId, {
    int page = 0,
  }) => _activities.listView(
    teachingPeriodId,
    (all) => localPage(all, page: page),
  );

  Future<void> ensureActivities(int teachingPeriodId) => _activities.ensure(
    teachingPeriodId,
    () => _repository.getAll(teachingPeriodId),
  );

  Future<void> refreshActivities(int teachingPeriodId) => _activities.refresh(
    teachingPeriodId,
    () => _repository.getAll(teachingPeriodId),
  );

  // --- One activity and its grades ----------------------------------------

  ActivityEntity? _fromLists(int id) {
    for (final tp in _activities.keys) {
      for (final a in _activities.dataOf(tp) ?? const <ActivityEntity>[]) {
        if (a.id == id) return a;
      }
    }
    return null;
  }

  DetailViewState<ActivityEntity> detail(int id) {
    final listed = _fromLists(id);
    return listed != null
        ? DetailViewState.success(listed)
        : _details.detailView(id);
  }

  /// No request when the activity is already in its class's list.
  Future<void> ensureDetail(int id) async {
    if (_fromLists(id) != null) return;
    await _details.ensure(id, () => _repository.getById(id));
  }

  Future<void> refreshDetail(int id) async {
    await _details.refresh(id, () => _repository.getById(id));
    final fresh = _details.dataOf(id);
    if (fresh != null) {
      _activities.update(
        fresh.teachingPeriodId,
        (list) => _upsert(list, fresh),
      );
    }
  }

  ListViewState<StudentGradeEntity> grades(int activityId) =>
      _grades.view(activityId);

  Future<void> ensureGrades(int activityId) =>
      _grades.ensure(activityId, () => _repository.getGrades(activityId));

  Future<void> refreshGrades(int activityId) =>
      _grades.refresh(activityId, () => _repository.getGrades(activityId));

  // --- Mutations -----------------------------------------------------------

  AppException? _lastError;
  AppException? get lastError => _lastError;

  Future<ActivityEntity?> create({
    required int teachingPeriodId,
    required String name,
    String? description,
    DateTime? evaluationDate,
    required double maximumScore,
    String? activityType,
  }) async {
    try {
      final activity = await _repository.create(
        teachingPeriodId: teachingPeriodId,
        name: name,
        description: description,
        evaluationDate: evaluationDate,
        maximumScore: maximumScore,
        activityType: activityType,
      );
      _announce(activity.teachingPeriodId, ClassAspect.activities);
      _details.set(activity.id, activity);
      _activities.update(
        activity.teachingPeriodId,
        (list) => _upsert(list, activity),
      );
      return activity;
    } on AppException catch (e) {
      _lastError = e;
      return null;
    }
  }

  /// Saves every edited grade in a single request (§99: batch save,
  /// mirroring the attendance roster pattern — not one round trip per
  /// student). The API answers with the activity's grades.
  Future<AppException?> saveGrades(
    int activityId,
    List<({int studentId, double grade, String? comment})> grades,
  ) async {
    try {
      final result = await _repository.putGrades(activityId, grades);
      final teachingPeriodId = detail(activityId).data?.teachingPeriodId;
      if (teachingPeriodId != null) {
        _announce(teachingPeriodId, ClassAspect.grades);
      }
      _grades.set(activityId, result);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> delete(int id, {required int teachingPeriodId}) async {
    try {
      await _repository.delete(id);
    } on AppException catch (e) {
      return e;
    }
    _announce(teachingPeriodId, ClassAspect.activities);
    _activities.update(
      teachingPeriodId,
      (list) => list.where((a) => a.id != id).toList(),
    );
    _details.remove(id);
    _grades.remove(id);
    return null;
  }

  // --- Helpers -------------------------------------------------------------

  void _announce(int teachingPeriodId, ClassAspect aspect) =>
      publish(ClassDataChanged(teachingPeriodId, {aspect}));

  /// Keeps the API's order: newest date first, undated last, then newest.
  static List<ActivityEntity> _upsert(
    List<ActivityEntity> list,
    ActivityEntity activity,
  ) => [
    for (final a in list)
      if (a.id != activity.id) a,
    activity,
  ]..sort(_apiOrder);

  static int _apiOrder(ActivityEntity a, ActivityEntity b) {
    final da = a.evaluationDate;
    final db = b.evaluationDate;
    if (da != null && db != null && da != db) return db.compareTo(da);
    if ((da == null) != (db == null)) return da == null ? 1 : -1;
    return b.id.compareTo(a.id);
  }

  @override
  void onDomainEvent(DomainEvent event) {
    switch (event) {
      case ClassDataChanged(:final teachingPeriodId)
          when event.affects(const {ClassAspect.grades, ClassAspect.roster}):
        // A grade entered elsewhere (a student's grade detail) or a roster
        // change shows in this class's activity grade sheets.
        final ids = {
          for (final a in _activities.dataOf(teachingPeriodId) ?? const [])
            a.id,
        };
        _grades.invalidateWhere(
          (activityId, _) =>
              ids.contains(activityId) ||
              detail(activityId).data?.teachingPeriodId == teachingPeriodId,
        );
      case StudentsChanged():
        _grades.invalidateAll();
      case CatalogChanged(resource: CatalogResource.teachingPeriods)
          when event.change == CatalogChange.deleted:
        _activities.invalidateAll();
      default:
        break;
    }
  }
}
