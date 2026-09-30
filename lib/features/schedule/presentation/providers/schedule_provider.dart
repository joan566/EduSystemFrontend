import '../../../../core/cache/keyed_cache.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../domain/entities/schedule_entities.dart';

/// The teacher's agenda (today, the coming week, calendar weeks) and each
/// class's weekly blocks.
///
/// Today and the coming week depend on the clock, so they expire after
/// [agendaMaxAge] and are re-read when the app comes back to the
/// foreground. Calendar ranges and class blocks only change when a block
/// (or a class) changes.
class ScheduleProvider extends SessionNotifier {
  ScheduleProvider(this._repository, DomainEvents events) : super(events);

  static const agendaMaxAge = Duration(minutes: 5);

  final ScheduleRepository _repository;

  late final _today = cachedValue<DayScheduleEntity>(maxAge: agendaMaxAge);

  /// The next 7 days — the dashboard counts weekly sessions per class.
  late final _week = cachedValue<ScheduleRangeEntity>(maxAge: agendaMaxAge);

  /// Calendar weeks already seen, by (from, to).
  late final _calendar = keyedCache<(DateTime, DateTime), ScheduleRangeEntity>(
    maxEntries: 12,
  );

  late final _classSchedules = keyedCache<int, List<ClassScheduleEntity>>();

  DetailViewState<DayScheduleEntity> get today => _today.detailView;
  DetailViewState<ScheduleRangeEntity> get week => _week.detailView;

  /// The calendar range from [from] to [to] (whole days).
  DetailViewState<ScheduleRangeEntity> calendar(DateTime from, DateTime to) =>
      _calendar.detailView(_rangeKey(from, to));

  ListViewState<ClassScheduleEntity> classSchedules(int teachingPeriodId) =>
      _classSchedules.view(teachingPeriodId);

  Future<void> ensureToday() => _today.ensure(_repository.getToday);
  Future<void> refreshToday() => _today.refresh(_repository.getToday);

  Future<void> ensureWeek() => _week.ensure(_repository.getRange);
  Future<void> refreshWeek() => _week.refresh(_repository.getRange);

  Future<void> ensureCalendar(DateTime from, DateTime to) => _calendar.ensure(
    _rangeKey(from, to),
    () => _repository.getRange(from: from, to: to),
  );

  Future<void> refreshCalendar(DateTime from, DateTime to) => _calendar.refresh(
    _rangeKey(from, to),
    () => _repository.getRange(from: from, to: to),
  );

  Future<void> ensureClassSchedules(int teachingPeriodId) =>
      _classSchedules.ensure(
        teachingPeriodId,
        () => _repository.getClassSchedules(teachingPeriodId),
      );

  Future<void> refreshClassSchedules(int teachingPeriodId) =>
      _classSchedules.refresh(
        teachingPeriodId,
        () => _repository.getClassSchedules(teachingPeriodId),
      );

  static (DateTime, DateTime) _rangeKey(DateTime from, DateTime to) => (
    DateTime(from.year, from.month, from.day),
    DateTime(to.year, to.month, to.day),
  );

  /// Creates ([scheduleId] null) or updates a weekly block. The API
  /// answers without the blocks, so only that class's blocks are re-read;
  /// the agenda views just go stale.
  Future<AppException?> saveClassSchedule(
    int teachingPeriodId, {
    int? scheduleId,
    required int dayOfWeek,
    required ClockTime startTime,
    required ClockTime endTime,
    String? room,
  }) async {
    try {
      await _repository.saveClassSchedule(
        teachingPeriodId,
        scheduleId: scheduleId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        room: room,
      );
    } on AppException catch (e) {
      return e;
    }
    await _afterChange(teachingPeriodId);
    return null;
  }

  Future<AppException?> deleteClassSchedule(
    int teachingPeriodId,
    int scheduleId,
  ) async {
    try {
      await _repository.deleteClassSchedule(teachingPeriodId, scheduleId);
    } on AppException catch (e) {
      return e;
    }
    await _afterChange(teachingPeriodId);
    return null;
  }

  Future<void> _afterChange(int teachingPeriodId) {
    publish(ClassDataChanged(teachingPeriodId, const {ClassAspect.schedule}));
    return refreshClassSchedules(teachingPeriodId);
  }

  void _invalidateAgenda() {
    _today.invalidate();
    _week.invalidate();
    _calendar.invalidateAll();
  }

  @override
  void onDomainEvent(DomainEvent event) {
    switch (event) {
      case ClassDataChanged(:final aspects)
          when aspects.contains(ClassAspect.schedule):
        _invalidateAgenda();
      case CatalogChanged(:final resource)
          when const {
                CatalogResource.teachingPeriods,
                CatalogResource.teachingAssignments,
              }.contains(resource) ||
              event.renamesOrRemoves:
        // Classes appear, disappear or are renamed in the agenda.
        _invalidateAgenda();
      case AppResumed():
        // What "today" and "next class" mean has moved on.
        _today.invalidate();
        _week.invalidate();
      default:
        break;
    }
  }
}
