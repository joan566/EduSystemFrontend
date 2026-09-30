import '../../../../core/cache/catalog.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/course_repository.dart';
import '../../domain/entities/course_entity.dart';

/// The teacher's courses (groups), a session catalog of every level and
/// year. The Cursos screen's level/year filters are its own state and are
/// applied in memory.
class CoursesProvider extends SessionNotifier {
  CoursesProvider(this._repository, DomainEvents events) : super(events);

  final CourseRepository _repository;

  late final Catalog<CourseEntity> _courses = Catalog(
    cachedValue(),
    idOf: (c) => c.id,
    fetch: _repository.getAll,
    compare: _apiOrder,
  );

  /// The API's order: newest year first, then level and course name.
  static int _apiOrder(CourseEntity a, CourseEntity b) {
    final byYear = b.academicYear.compareTo(a.academicYear);
    if (byYear != 0) return byYear;
    final byLevel = a.gradeName.toLowerCase().compareTo(
      b.gradeName.toLowerCase(),
    );
    return byLevel != 0
        ? byLevel
        : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  /// Every course (empty until loaded) — what forms offer.
  List<CourseEntity> get all => _courses.items;

  /// The whole catalog's load state.
  ListViewState<CourseEntity> get state => _courses.view;

  static bool Function(CourseEntity) _matching(int? gradeId, int? year) =>
      (c) =>
          (gradeId == null || c.gradeId == gradeId) &&
          (year == null || c.academicYear == year);

  /// One page of the courses of [gradeId] in [academicYear] (null: any).
  ListViewState<CourseEntity> query({
    int? gradeId,
    int? academicYear,
    int page = 0,
  }) => _courses.page(where: _matching(gradeId, academicYear), page: page);

  /// Every course of [gradeId] in [academicYear] (null: any).
  List<CourseEntity> matching({int? gradeId, int? academicYear}) =>
      all.where(_matching(gradeId, academicYear)).toList();

  Future<void> ensure() => _courses.ensure();
  Future<void> refresh() => _courses.refresh();

  Future<AppException?> create({
    required int gradeId,
    required String name,
    required int academicYear,
  }) => _mutate(CatalogChange.created, () async {
    _courses.upsert(
      await _repository.create(
        gradeId: gradeId,
        name: name,
        academicYear: academicYear,
      ),
    );
  });

  Future<AppException?> update(
    int id, {
    required String name,
    required int academicYear,
  }) => _mutate(CatalogChange.updated, () async {
    _courses.upsert(
      await _repository.update(id, name: name, academicYear: academicYear),
    );
  });

  Future<AppException?> delete(int id) =>
      _mutate(CatalogChange.deleted, () async {
        await _repository.delete(id);
        _courses.remove(id);
      });

  @override
  void onDomainEvent(DomainEvent event) {
    // Courses embed their level's name.
    if (event is CatalogChanged &&
        event.resource == CatalogResource.academicLevels &&
        event.renamesOrRemoves) {
      _courses.invalidate();
    }
  }

  Future<AppException?> _mutate(
    CatalogChange change,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      publish(CatalogChanged(CatalogResource.courses, change));
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
