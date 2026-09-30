import '../../../../core/cache/keyed_cache.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/list_state.dart';
import '../../data/datasources/audit_remote_datasource.dart';
import '../../domain/entities/audit_log_entity.dart';

/// One page of the audit feed with its filters.
typedef AuditQuery = ({int page, String? action, int? teachingPeriodId});

/// The audit trail: the account-wide feed (by page and filters) and each
/// class's latest actions.
///
/// Every mutation adds entries, so any domain event marks the feed stale
/// (a class's events only that class's logs). It is re-read when shown,
/// and never trusted for more than [maxAge] in any case.
class AuditProvider extends SessionNotifier {
  AuditProvider(this._remote, DomainEvents events) : super(events);

  static const maxAge = Duration(minutes: 2);

  /// The unfiltered first page: the dashboard's "Actividad reciente".
  static const AuditQuery recentQuery = (
    page: 0,
    action: null,
    teachingPeriodId: null,
  );

  final AuditRemoteDataSource _remote;

  late final _feed = keyedCache<AuditQuery, ApiPage<AuditLogEntity>>(
    maxEntries: 20,
    maxAge: maxAge,
  );

  late final _classLogs = keyedCache<int, ApiPage<AuditLogEntity>>(
    maxEntries: 30,
    maxAge: maxAge,
  );

  ListViewState<AuditLogEntity> feed(AuditQuery query) => _feed.view(query);

  /// The dashboard's latest actions.
  ListViewState<AuditLogEntity> get recent => _feed.view(recentQuery);

  Future<void> ensureFeed(AuditQuery query) =>
      _feed.ensure(query, () => _fetch(query));

  Future<void> refreshFeed(AuditQuery query) =>
      _feed.refresh(query, () => _fetch(query));

  Future<ApiPage<AuditLogEntity>> _fetch(AuditQuery q) => _remote.getPage(
    page: q.page,
    action: q.action,
    teachingPeriodId: q.teachingPeriodId,
  );

  /// Latest actions of one class (e.g. its "Actividad reciente"). Kept
  /// apart from [feed] so it never filters the account-wide feeds.
  ListViewState<AuditLogEntity> classLogs(int teachingPeriodId) =>
      _classLogs.view(teachingPeriodId);

  Future<void> ensureClassLogs(int teachingPeriodId) => _classLogs.ensure(
    teachingPeriodId,
    () => _remote.getPage(size: 5, teachingPeriodId: teachingPeriodId),
  );

  Future<void> refreshClassLogs(int teachingPeriodId) => _classLogs.refresh(
    teachingPeriodId,
    () => _remote.getPage(size: 5, teachingPeriodId: teachingPeriodId),
  );

  @override
  void onDomainEvent(DomainEvent event) {
    switch (event) {
      case AppResumed():
        _feed.invalidateAll();
        _classLogs.invalidateAll();
      case ClassDataChanged(:final teachingPeriodId):
        _feed.invalidateAll();
        _classLogs.invalidate(teachingPeriodId);
      default:
        // Any other change was a mutation somewhere: it's in the trail now.
        _feed.invalidateAll();
        _classLogs.invalidateAll();
    }
  }
}
