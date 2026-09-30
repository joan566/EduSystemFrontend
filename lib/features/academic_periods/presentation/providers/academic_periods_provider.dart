import '../../../../core/cache/catalog.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/academic_period_repository.dart';
import '../../domain/entities/academic_period_entity.dart';

/// The teacher's academic periods, a session catalog (all pages), newest
/// first like the API.
class AcademicPeriodsProvider extends SessionNotifier {
  AcademicPeriodsProvider(this._repository, DomainEvents events)
    : super(events);

  final AcademicPeriodRepository _repository;

  late final Catalog<AcademicPeriodEntity> _periods = Catalog(
    cachedValue(),
    idOf: (p) => p.id,
    fetch: _repository.getAll,
    compare: (a, b) => b.startDate.compareTo(a.startDate),
  );

  /// Every period, newest first (empty until loaded).
  List<AcademicPeriodEntity> get all => _periods.items;

  /// The whole catalog as a screen state.
  ListViewState<AcademicPeriodEntity> get state => _periods.view;

  /// One page of the periods matching [where].
  ListViewState<AcademicPeriodEntity> query({
    bool Function(AcademicPeriodEntity period)? where,
    int page = 0,
  }) => _periods.page(where: where, page: page);

  Future<void> ensure() => _periods.ensure();
  Future<void> refresh() => _periods.refresh();

  Future<AppException?> create({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) => _mutate(CatalogChange.created, () async {
    _periods.upsert(
      await _repository.create(
        name: name,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  });

  Future<AppException?> update(
    int id, {
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) => _mutate(CatalogChange.updated, () async {
    _periods.upsert(
      await _repository.update(
        id,
        name: name,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  });

  Future<AppException?> delete(int id) =>
      _mutate(CatalogChange.deleted, () async {
        await _repository.delete(id);
        _periods.remove(id);
      });

  Future<AppException?> _mutate(
    CatalogChange change,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      publish(CatalogChanged(CatalogResource.academicPeriods, change));
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
