import '../../../../core/cache/catalog.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/subject_repository.dart';
import '../../../teaching/presentation/shared/class_lookup.dart';
import '../../domain/entities/subject_entity.dart';

/// The teacher's subjects, a session catalog. The screen's search and page
/// are its own state; searching and paging happen in memory.
class SubjectsProvider extends SessionNotifier {
  SubjectsProvider(this._repository, DomainEvents events) : super(events);

  final SubjectRepository _repository;

  late final Catalog<SubjectEntity> _subjects = Catalog(
    cachedValue(),
    idOf: (s) => s.id,
    fetch: _repository.getAll,
    // The API lists them by name.
    compare: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );

  /// Every subject (empty until loaded) — what forms and filters offer.
  List<SubjectEntity> get all => _subjects.items;

  /// The whole catalog's load state.
  ListViewState<SubjectEntity> get state => _subjects.view;

  /// One page of the subjects whose name matches [search].
  ListViewState<SubjectEntity> query({String? search, int page = 0}) =>
      _subjects.page(
        where: (s) => matchesSearch(search ?? '', [s.name]),
        page: page,
      );

  Future<void> ensure() => _subjects.ensure();
  Future<void> refresh() => _subjects.refresh();

  Future<AppException?> create({required String name, String? description}) =>
      _mutate(CatalogChange.created, () async {
        _subjects.upsert(
          await _repository.create(name: name, description: description),
        );
      });

  Future<AppException?> update(
    int id, {
    required String name,
    String? description,
  }) => _mutate(CatalogChange.updated, () async {
    _subjects.upsert(
      await _repository.update(id, name: name, description: description),
    );
  });

  Future<AppException?> delete(int id) =>
      _mutate(CatalogChange.deleted, () async {
        await _repository.delete(id);
        _subjects.remove(id);
      });

  Future<AppException?> _mutate(
    CatalogChange change,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      publish(CatalogChanged(CatalogResource.subjects, change));
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
