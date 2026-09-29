import 'package:intl/intl.dart';

import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../domain/entities/academic_period_entity.dart';

enum PeriodStatus { active, upcoming, finished }

enum PeriodStatusFilter { all, active, upcoming, finished }

String periodFilterLabel(PeriodStatusFilter f) => switch (f) {
  PeriodStatusFilter.all => 'Todos',
  PeriodStatusFilter.active => 'En curso',
  PeriodStatusFilter.upcoming => 'Próximos',
  PeriodStatusFilter.finished => 'Finalizados',
};

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

PeriodStatus periodStatus(AcademicPeriodEntity p, [DateTime? now]) {
  final today = _day(now ?? DateTime.now());
  if (today.isBefore(_day(p.startDate))) return PeriodStatus.upcoming;
  if (today.isAfter(_day(p.endDate))) return PeriodStatus.finished;
  return PeriodStatus.active;
}

bool matchesPeriodFilter(AcademicPeriodEntity p, PeriodStatusFilter f) =>
    switch (f) {
      PeriodStatusFilter.all => true,
      PeriodStatusFilter.active => periodStatus(p) == PeriodStatus.active,
      PeriodStatusFilter.upcoming => periodStatus(p) == PeriodStatus.upcoming,
      PeriodStatusFilter.finished => periodStatus(p) == PeriodStatus.finished,
    };

({String label, AppStatusKind kind}) periodStatusLabel(PeriodStatus s) =>
    switch (s) {
      PeriodStatus.active => (label: 'En curso', kind: AppStatusKind.success),
      PeriodStatus.upcoming => (label: 'Próximo', kind: AppStatusKind.info),
      PeriodStatus.finished => (
        label: 'Finalizado',
        kind: AppStatusKind.neutral,
      ),
    };

/// Whole weeks the period spans (at least 1).
int periodWeeks(AcademicPeriodEntity p) =>
    ((_day(p.endDate).difference(_day(p.startDate)).inDays + 1) / 7)
        .ceil()
        .clamp(1, 1000);

/// The current week (1-based) while the period is running, else null.
int? currentWeek(AcademicPeriodEntity p, [DateTime? now]) {
  if (periodStatus(p, now) != PeriodStatus.active) return null;
  final days = _day(now ?? DateTime.now()).difference(_day(p.startDate)).inDays;
  return (days ~/ 7 + 1).clamp(1, periodWeeks(p));
}

/// How far into the period today is, 0..1.
double periodProgress(AcademicPeriodEntity p, [DateTime? now]) {
  final total = _day(p.endDate).difference(_day(p.startDate)).inDays + 1;
  final done =
      _day(now ?? DateTime.now()).difference(_day(p.startDate)).inDays + 1;
  return total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

/// "3 feb – 14 jun 2026" (the year once when both dates share it).
String periodRange(AcademicPeriodEntity p) {
  final sameYear = p.startDate.year == p.endDate.year;
  final start = DateFormat(sameYear ? 'd MMM' : 'd MMM y').format(p.startDate);
  final end = DateFormat('d MMM y').format(p.endDate);
  return '$start – $end';
}

String monthShort(DateTime d) =>
    DateFormat('MMM').format(d).replaceAll('.', '').toUpperCase();

/// The teacher's classes in each academic period, by period id.
Map<int, int> classesByPeriod(List<TeachingPeriodEntity> classes) {
  final result = <int, int>{};
  for (final c in classes) {
    result[c.academicPeriodId] = (result[c.academicPeriodId] ?? 0) + 1;
  }
  return result;
}

/// Newest first: running, then upcoming (soonest first), then finished.
List<AcademicPeriodEntity> sortPeriods(List<AcademicPeriodEntity> periods) {
  int rank(AcademicPeriodEntity p) => switch (periodStatus(p)) {
    PeriodStatus.active => 0,
    PeriodStatus.upcoming => 1,
    PeriodStatus.finished => 2,
  };
  return [...periods]..sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    return rank(a) == 1
        ? a.startDate.compareTo(b.startDate)
        : b.startDate.compareTo(a.startDate);
  });
}
