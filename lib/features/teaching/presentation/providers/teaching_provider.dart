import '../../../../core/cache/catalog.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/course_naming.dart';
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

  // Newest first, then grade in natural order ("6°" before "10°"), group
  // and subject; kept after local inserts.
  static int _assignmentOrder(
    TeachingAssignmentEntity a,
    TeachingAssignmentEntity b,
  ) {
    final byYear = b.academicYear.compareTo(a.academicYear);
    if (byYear != 0) return byYear;
    return _courseSubjectOrder(
      (a.gradeName, a.groupName, a.subjectName),
      (b.gradeName, b.groupName, b.subjectName),
    );
  }

  static int _periodOrder(TeachingPeriodEntity a, TeachingPeriodEntity b) {
    final byStart = b.startDate.compareTo(a.startDate);
    if (byStart != 0) return byStart;
    return _courseSubjectOrder(
      (a.gradeName, a.groupName, a.subjectName),
      (b.gradeName, b.groupName, b.subjectName),
    );
  }

  static int _courseSubjectOrder(
    (String, String, String) a,
    (String, String, String) b,
  ) {
    final byGrade = compareGradeNames(a.$1, b.$1);
    if (byGrade != 0) return byGrade;
    for (final (x, y) in [(a.$2, b.$2), (a.$3, b.$3)]) {
      final c = x.toLowerCase().compareTo(y.toLowerCase());
      if (c != 0) return c;
    }
    return 0;
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

  /// Teaches [subjectIds] in course [groupId]: creates the assignments that
  /// don't exist yet and, when [academicPeriodId] is given, each one's
  /// class in that period. Stops at the first failure, keeping what was
  /// already created; [created] counts the classes (or, without a period,
  /// the assignments) that are new.
  Future<({int created, AppException? error})> addClasses({
    required int groupId,
    required List<int> subjectIds,
    int? academicPeriodId,
  }) async {
    var created = 0;
    var newAssignments = false;
    var newClasses = false;
    AppException? error;
    try {
      for (final subjectId in subjectIds) {
        var assignment = _assignments.items
            .where((a) => a.groupId == groupId && a.subjectId == subjectId)
            .firstOrNull;
        if (assignment == null) {
          assignment = await _repository.createAssignment(
            groupId: groupId,
            subjectId: subjectId,
          );
          _assignments.upsert(assignment);
          newAssignments = true;
          if (academicPeriodId == null) created++;
        }
        if (academicPeriodId == null) continue;
        final id = assignment.id;
        final exists = _periods.items.any(
          (p) =>
              p.teachingAssignmentId == id &&
              p.academicPeriodId == academicPeriodId,
        );
        if (exists) continue;
        _periods.upsert(
          await _repository.createPeriod(
            teachingAssignmentId: id,
            academicPeriodId: academicPeriodId,
          ),
        );
        newClasses = true;
        created++;
      }
    } on AppException catch (e) {
      error = e;
    }
    if (newAssignments) {
      publish(
        const CatalogChanged(
          CatalogResource.teachingAssignments,
          CatalogChange.created,
        ),
      );
    }
    if (newClasses) {
      publish(
        const CatalogChanged(
          CatalogResource.teachingPeriods,
          CatalogChange.created,
        ),
      );
    }
    return (created: created, error: error);
  }

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

  /// Assignments whose class is being created right now, so every
  /// "Crear clase" button for them shows it and can't send a second create.
  final Set<int> _creatingClassFor = {};

  bool isCreatingClassFor(int teachingAssignmentId) =>
      _creatingClassFor.contains(teachingAssignmentId);

  Future<AppException?> createPeriod({
    required int teachingAssignmentId,
    required int academicPeriodId,
  }) async {
    _creatingClassFor.add(teachingAssignmentId);
    notifyListeners();
    try {
      return await _guard(() async {
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
    } finally {
      _creatingClassFor.remove(teachingAssignmentId);
      notifyListeners();
    }
  }

  Future<AppException?> deletePeriod(int id) => _guard(() async {
    await _repository.deletePeriod(id);
    _periods.remove(id);
    _periodDetails.remove(id);
    _summaries.remove(id);
    if (_lastClassId == id) _lastClassId = null;
    publish(
      const CatalogChanged(
        CatalogResource.teachingPeriods,
        CatalogChange.deleted,
      ),
    );
  });

  // --- Last class used --------------------------------------------------

  /// The class last picked in any module this session (memory only), so
  /// Asistencia, Actividades, Calificaciones... open on it.
  int? get lastClassId => _lastClassId;
  int? _lastClassId;

  /// Not a change anyone watches: no notification.
  void rememberClass(int teachingPeriodId) => _lastClassId = teachingPeriodId;

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
