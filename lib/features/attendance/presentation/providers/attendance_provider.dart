import '../../../../core/cache/keyed_cache.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../domain/entities/attendance_entity.dart';

/// Attendance: each class's latest sessions (most recent first) and each
/// class's attendance on each date, which is what the screen marks.
///
/// A date already opened comes from memory (switching back to it costs
/// nothing); saving writes the backend's answer into that day and into the
/// class's sessions instead of re-reading them.
class AttendanceProvider extends SessionNotifier {
  AttendanceProvider(this._repository, DomainEvents events) : super(events);

  final AttendanceRepository _repository;

  /// teachingPeriodId → its latest sessions (first page).
  late final _sessions = keyedCache<int, ApiPage<AttendanceSessionEntity>>();

  /// (teachingPeriodId, date) → that day. Bounded: one per date visited.
  late final _days = keyedCache<(int, DateTime), AttendanceDayEntity>(
    maxEntries: 60,
  );

  static (int, DateTime) _dayKey(int teachingPeriodId, DateTime date) =>
      (teachingPeriodId, DateTime(date.year, date.month, date.day));

  // --- Reads ---------------------------------------------------------------

  ListViewState<AttendanceSessionEntity> sessions(int teachingPeriodId) =>
      _sessions.view(teachingPeriodId);

  Future<void> ensureSessions(int teachingPeriodId) => _sessions.ensure(
    teachingPeriodId,
    () => _repository.getPage(teachingPeriodId: teachingPeriodId),
  );

  DetailViewState<AttendanceDayEntity> day(
    int teachingPeriodId,
    DateTime date,
  ) => _days.detailView(_dayKey(teachingPeriodId, date));

  Future<void> ensureDay(int teachingPeriodId, DateTime date) => _days.ensure(
    _dayKey(teachingPeriodId, date),
    () => _repository.getDay(teachingPeriodId: teachingPeriodId, date: date),
  );

  Future<void> refreshDay(int teachingPeriodId, DateTime date) => _days.refresh(
    _dayKey(teachingPeriodId, date),
    () => _repository.getDay(teachingPeriodId: teachingPeriodId, date: date),
  );

  // --- Save ----------------------------------------------------------------

  /// Saves [records] for the class on [date], creating that day's session
  /// first if it doesn't exist yet. The answer (session + roster) replaces
  /// the cached day and updates the class's session list.
  Future<AppException?> saveDay(
    int teachingPeriodId,
    DateTime date,
    List<({int studentId, AttendanceStatus status, String? observation})>
    records,
  ) async {
    final key = _dayKey(teachingPeriodId, date);
    final current = _days.dataOf(key);
    if (current == null) return null;
    try {
      final session =
          current.session ??
          await _repository.create(
            teachingPeriodId: teachingPeriodId,
            sessionDate: current.date,
          );
      final detail = await _repository.putRecords(session.id, records);
      publish(
        ClassDataChanged(teachingPeriodId, const {ClassAspect.attendance}),
      );
      _days.set(
        key,
        AttendanceDayEntity(
          teachingPeriodId: teachingPeriodId,
          date: current.date,
          session: detail.session,
          students: detail.students,
        ),
      );
      _sessions.update(
        teachingPeriodId,
        (page) => _withSession(page, detail.session),
      );
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  /// [page] with [session] inserted (a new day) or replaced, in the API's
  /// order (newest date first), keeping the page size.
  static ApiPage<AttendanceSessionEntity> _withSession(
    ApiPage<AttendanceSessionEntity> page,
    AttendanceSessionEntity session,
  ) {
    final isNew = page.content.every((s) => s.id != session.id);
    final content =
        [
          for (final s in page.content)
            if (s.id != session.id) s,
          session,
        ]..sort((a, b) {
          final byDate = b.sessionDate.compareTo(a.sessionDate);
          return byDate != 0 ? byDate : b.id.compareTo(a.id);
        });
    final pageSize = page.content.length < 20 ? 20 : page.content.length;
    return ApiPage(
      content: content.take(pageSize).toList(),
      page: page.page,
      totalPages: page.totalPages == 0 ? 1 : page.totalPages,
      totalElements: page.totalElements + (isNew ? 1 : 0),
    );
  }

  // --- Invalidation -------------------------------------------------------

  @override
  void onDomainEvent(DomainEvent event) {
    switch (event) {
      case ClassDataChanged(:final teachingPeriodId)
          when event.affects(const {ClassAspect.roster}):
        // Who is listed on each day changed.
        _days.invalidateWhere((key, _) => key.$1 == teachingPeriodId);
      case StudentsChanged():
        _days.invalidateAll();
      default:
        break;
    }
  }
}
