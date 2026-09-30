import '../../../../core/cache/catalog.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/teaching_repository.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../../domain/entities/teaching_period_summary_entity.dart';

/// Owns both teaching assignments (group + subject) and teaching periods
/// (assignment + academic period, "classes") — the two are tightly coupled
/// (§4) and splitting them into separate providers would just duplicate
/// wiring.
///
/// Both are session catalogs (every page, read once, kept in step with
/// mutations locally). Each class's summary is cached per class and goes
/// stale when something inside the class changes.
class TeachingProvider extends SessionNotifier {
  TeachingProvider(this._repository, DomainEvents events) : super(events);

  final TeachingRepository _repository;

  late final Catalog<TeachingAssignmentEntity> _assignments = Catalog(
    cachedValue(),
    idOf: (a) => a.id,
    fetch: _repository.getAllAssignments,
    compare: _assignmentOrder,
  );

  late final Catalog<TeachingPeriodEntity> _periods = Catalog(
    cachedValue(),
    idOf: (p) => p.id,
    fetch: _repository.getAllPeriods,
    compare: _periodOrder,
  );

  /// Classes read one by one, only when not in [allPeriods] (e.g. opened by
  /// a link before the catalog loaded).
  late final _periodDetails = keyedCache<int, TeachingPeriodEntity>();

  late final _summaries = keyedCache<int, TeachingPeriodSummaryEntity>();

  // The API's orders, kept after local inserts.
  static int _assignmentOrder(
    TeachingAssignmentEntity a,
    TeachingAssignmentEntity b,
  ) {
    final byYear = b.academicYear.compareTo(a.academicYear);
    if (byYear != 0) return byYear;
    for (final (x, y) in [
      (a.gradeName, b.gradeName),
      (a.groupName, b.groupName),
      (a.subjectName, b.subjectName),
    ]) {
      final c = x.toLowerCase().compareTo(y.toLowerCase());
      if (c != 0) return c;
    }
    return 0;
  }

  static int _periodOrder(TeachingPeriodEntity a, TeachingPeriodEntity b) {
    final byStart = b.startDate.compareTo(a.startDate);
    if (byStart != 0) return byStart;
    final byGroup = a.groupName.toLowerCase().compareTo(
      b.groupName.toLowerCase(),
    );
    return byGroup != 0
        ? byGroup
        : a.subjectName.toLowerCase().compareTo(b.subjectName.toLowerCase());
  }

  // --- Assignments ---------------------------------------------------------

  /// Every assignment (empty until loaded).
  List<TeachingAssignmentEntity> get allAssignments => _assignments.items;

  /// The whole assignment catalog as a screen state.
  ListViewState<TeachingAssignmentEntity> get assignmentsState =>
      _assignments.view;

  /// The assignments matching the Clases screen's filters (in memory).
  ListViewState<TeachingAssignmentEntity> assignments({
    int? subjectId,
    bool? active,
  }) => _assignments.filtered(
    (a) =>
        (subjectId == null || a.subjectId == subjectId) &&
        (active == null || a.active == active),
  );

  Future<void> ensureAssignments() => _assignments.ensure();
  Future<void> refreshAssignments() => _assignments.refresh();

  Future<AppException?> createAssignment({
    required int groupId,
    required int subjectId,
  }) => _guard(() async {
    _assignments.upsert(
      await _repository.createAssignment(
        groupId: groupId,
        subjectId: subjectId,
      ),
    );
    publish(
      const CatalogChanged(
        CatalogResource.teachingAssignments,
        CatalogChange.created,
      ),
    );
  });

  /// Optimistic: the switch flips at once and flips back if the API
  /// refuses.
  Future<AppException?> setAssignmentActive(int id, bool active) async {
    final previous = _assignments.byId(id)?.active;
    _assignments.patch(id, (a) => a.copyWith(active: active));
    try {
      await _repository.setAssignmentActive(id, active);
      publish(
        const CatalogChanged(
          CatalogResource.teachingAssignments,
          CatalogChange.updated,
        ),
      );
      return null;
    } on AppException catch (e) {
      if (previous != null) {
        _assignments.patch(id, (a) => a.copyWith(active: previous));
      }
      return e;
    }
  }

  Future<AppException?> deleteAssignment(int id) => _guard(() async {
    await _repository.deleteAssignment(id);
    _assignments.remove(id);
    // Its classes may be gone with it.
    _periods.invalidate();
    publish(
      const CatalogChanged(
        CatalogResource.teachingAssignments,
        CatalogChange.deleted,
      ),
    );
  });

  // --- Classes (teaching periods) -----------------------------------------

  /// Every class of the teacher, all pages (empty until loaded). Other
  /// features (exams, activities, attendance, grading) pick classes from
  /// here.
  List<TeachingPeriodEntity> get allPeriods => _periods.items;
  bool get allPeriodsLoaded => _periods.isLoaded;

  /// The whole class catalog as a screen state.
  ListViewState<TeachingPeriodEntity> get periodsState => _periods.view;

  /// Reads the class catalog once per session; concurrent callers share
  /// the request.
  Future<void> ensureAllPeriodsLoaded() => _periods.ensure();
  Future<void> refreshPeriods() => _periods.refresh();

  /// One class: from the catalog when it's there, else read on its own.
  DetailViewState<TeachingPeriodEntity> periodDetail(int id) {
    final fromCatalog = _periods.byId(id);
    if (fromCatalog != null) return DetailViewState.success(fromCatalog);
    final single = _periodDetails.detailView(id);
    if (single.status != DetailStatus.initial) return single;
    return _periods.isLoading
        ? DetailViewState<TeachingPeriodEntity>.loading()
        : single;
  }

  /// Makes [periodDetail] available without a request when the catalog
  /// has the class.
  Future<void> ensurePeriodDetail(int id) async {
    await _periods.ensure();
    if (isDisposed || _periods.byId(id) != null) return;
    await _periodDetails.ensure(id, () => _repository.getPeriod(id));
  }

  /// Re-reads one class (e.g. its student count) and updates the catalog.
  Future<void> refreshPeriodDetail(int id) async {
    await _periodDetails.refresh(id, () => _repository.getPeriod(id));
    final fresh = _periodDetails.dataOf(id);
    if (fresh != null) _periods.upsert(fresh);
  }

  Future<AppException?> createPeriod({
    required int teachingAssignmentId,
    required int academicPeriodId,
  }) => _guard(() async {
    _periods.upsert(
      await _repository.createPeriod(
        teachingAssignmentId: teachingAssignmentId,
        academicPeriodId: academicPeriodId,
      ),
    );
    publish(
      const CatalogChanged(
        CatalogResource.teachingPeriods,
        CatalogChange.created,
      ),
    );
  });

  Future<AppException?> deletePeriod(int id) => _guard(() async {
    await _repository.deletePeriod(id);
    _periods.remove(id);
    _periodDetails.remove(id);
    _summaries.remove(id);
    publish(
      const CatalogChanged(
        CatalogResource.teachingPeriods,
        CatalogChange.deleted,
      ),
    );
  });

  // --- Class summary ------------------------------------------------------

  /// Grading progress and counts of one class.
  DetailViewState<TeachingPeriodSummaryEntity> periodSummary(int id) =>
      _summaries.detailView(id);

  Future<void> ensurePeriodSummary(int id) =>
      _summaries.ensure(id, () => _repository.getPeriodSummary(id));

  Future<void> refreshPeriodSummary(int id) =>
      _summaries.refresh(id, () => _repository.getPeriodSummary(id));

  // --- Invalidation -------------------------------------------------------

  @override
  void onDomainEvent(DomainEvent event) {
    switch (event) {
      case CatalogChanged(:final resource) when event.renamesOrRemoves:
        // Assignments and classes embed subject, course, level and period
        // names (and the period's dates).
        if (const {
          CatalogResource.subjects,
          CatalogResource.courses,
          CatalogResource.academicLevels,
          CatalogResource.academicPeriods,
        }.contains(resource)) {
          _assignments.invalidate();
          _periods.invalidate();
          _periodDetails.invalidateAll();
        }
      case ClassDataChanged(:final teachingPeriodId, :final aspects):
        // Every aspect of a class shows up in its summary.
        _summaries.invalidate(teachingPeriodId);
        if (aspects.contains(ClassAspect.roster)) {
          _invalidateStudentCounts();
        }
      case StudentsChanged():
        _invalidateStudentCounts();
        _summaries.invalidateAll();
      case ExamResultsChanged(teachingPeriodId: null):
        _summaries.invalidateAll();
      default:
        break;
    }
  }

  /// Classes carry their student count.
  void _invalidateStudentCounts() {
    _periods.invalidate();
    _periodDetails.invalidateAll();
  }

  Future<AppException?> _guard(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
