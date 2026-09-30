import '../../../../core/cache/keyed_cache.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/entities/student_entity.dart';

/// A page of the student listing as the API serves it.
typedef StudentQuery = ({int page, int size, int? groupId, String? search});

/// Students. The teacher's whole student list is never loaded: the listing
/// stays paginated and searched by the server, and each exact query
/// (page, size, course, search) is cached, so repeating it (going back,
/// switching screens) costs nothing. Each group's roster and each
/// student's detail are cached by id.
class StudentsProvider extends SessionNotifier {
  StudentsProvider(this._repository, DomainEvents events) : super(events);

  final StudentRepository _repository;

  /// Bounded: pages and searches visited this session.
  late final _queries = keyedCache<StudentQuery, ApiPage<StudentEntity>>(
    maxEntries: 40,
  );

  late final _rosters = keyedCache<int, List<StudentEntity>>();

  late final _details = keyedCache<int, StudentDetailEntity>(maxEntries: 40);

  static StudentQuery queryOf({
    int page = 0,
    int size = 20,
    int? groupId,
    String? search,
  }) {
    final text = search?.trim();
    return (
      page: page,
      size: size,
      groupId: groupId,
      search: text == null || text.isEmpty ? null : text,
    );
  }

  // --- Listing -------------------------------------------------------------

  ListViewState<StudentEntity> query(StudentQuery query) =>
      _queries.view(query);

  Future<void> ensureQuery(StudentQuery query) =>
      _queries.ensure(query, () => _fetch(query));

  Future<void> refreshQuery(StudentQuery query) =>
      _queries.refresh(query, () => _fetch(query));

  Future<ApiPage<StudentEntity>> _fetch(StudentQuery q) => _repository.getPage(
    page: q.page,
    size: q.size,
    groupId: q.groupId,
    search: q.search,
  );

  /// The teacher's number of students, from a one-row page (never the
  /// whole list).
  static final StudentQuery _count = queryOf(size: 1);

  int? get totalStudents => _queries.dataOf(_count)?.totalElements;
  ListViewState<StudentEntity> get totalState => _queries.view(_count);
  Future<void> ensureTotal() => ensureQuery(_count);
  Future<void> refreshTotal() => refreshQuery(_count);

  // --- Group rosters -------------------------------------------------------

  /// Students of one group (a class's roster), all of them.
  ListViewState<StudentEntity> groupRoster(int groupId) =>
      _rosters.view(groupId);

  Future<void> ensureGroupRoster(int groupId) =>
      _rosters.ensure(groupId, () => _repository.getGroup(groupId));

  Future<void> refreshGroupRoster(int groupId) =>
      _rosters.refresh(groupId, () => _repository.getGroup(groupId));

  // --- Detail --------------------------------------------------------------

  DetailViewState<StudentDetailEntity> detail(int id) =>
      _details.detailView(id);

  Future<void> ensureDetail(int id) =>
      _details.ensure(id, () => _repository.getById(id));

  Future<void> refreshDetail(int id) =>
      _details.refresh(id, () => _repository.getById(id));

  // --- Mutations -----------------------------------------------------------

  /// Withdraws the student from a group. The API answers without the new
  /// state, so only this student's detail is re-read; listings and
  /// rosters go stale.
  Future<AppException?> withdraw(int studentId, int groupId) async {
    try {
      await _repository.withdraw(studentId, groupId);
    } on AppException catch (e) {
      return e;
    }
    publish(StudentsChanged(studentId: studentId));
    if (_details.peek(studentId) != null) await refreshDetail(studentId);
    return null;
  }

  /// Deletes the student and all of their data (irreversible).
  Future<AppException?> delete(int studentId) async {
    try {
      await _repository.delete(studentId);
    } on AppException catch (e) {
      return e;
    }
    publish(StudentsChanged(studentId: studentId));
    _details.remove(studentId);
    return null;
  }

  @override
  void onDomainEvent(DomainEvent event) {
    switch (event) {
      case StudentsChanged(:final studentId):
        // Pages, counts and rosters may all include (or have lost) them.
        _queries.invalidateAll();
        _rosters.invalidateAll();
        _details.invalidateWhere(
          (id, _) => studentId == null || id == studentId,
        );
      case ClassDataChanged(:final aspects)
          when aspects.contains(ClassAspect.roster):
        _rosters.invalidateAll();
        _queries.invalidateAll();
      case CatalogChanged(resource: CatalogResource.courses)
          when event.renamesOrRemoves:
        // Listings and details show each student's course.
        _queries.invalidateAll();
        _details.invalidateAll();
        _rosters.invalidateAll();
      default:
        break;
    }
  }
}
