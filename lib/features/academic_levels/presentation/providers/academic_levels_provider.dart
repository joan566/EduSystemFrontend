import '../../../../core/cache/catalog.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/academic_level_repository.dart';
import '../../domain/entities/academic_level_entity.dart';

/// The teacher's academic levels ("grados"), a session catalog: read once,
/// then kept in step with create/update/delete locally.
class AcademicLevelsProvider extends SessionNotifier {
  AcademicLevelsProvider(this._repository, DomainEvents events) : super(events);

  final AcademicLevelRepository _repository;

  late final Catalog<AcademicLevelEntity> _levels = Catalog(
    cachedValue(),
    idOf: (l) => l.id,
    fetch: _repository.getAll,
    // The API lists them by name.
    compare: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );

  /// Every level (empty until loaded).
  List<AcademicLevelEntity> get all => _levels.items;
  ListViewState<AcademicLevelEntity> get state => _levels.view;

  Future<void> ensure() => _levels.ensure();
  Future<void> refresh() => _levels.refresh();

  Future<AppException?> create({required String name, String? description}) =>
      _mutate(CatalogChange.created, () async {
        _levels.upsert(
          await _repository.create(name: name, description: description),
        );
      });

  Future<AppException?> update(
    int id, {
    required String name,
    String? description,
  }) => _mutate(CatalogChange.updated, () async {
    _levels.upsert(
      await _repository.update(id, name: name, description: description),
    );
  });

  Future<AppException?> delete(int id) =>
      _mutate(CatalogChange.deleted, () async {
        await _repository.delete(id);
        _levels.remove(id);
      });

  Future<AppException?> _mutate(
    CatalogChange change,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      publish(CatalogChanged(CatalogResource.academicLevels, change));
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
