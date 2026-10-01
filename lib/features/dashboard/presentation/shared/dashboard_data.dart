import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../../academic_periods/presentation/providers/academic_periods_provider.dart';
import '../../../audit/presentation/providers/audit_provider.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../../teaching/presentation/shared/class_grouping.dart';
import '../../../teaching/presentation/shared/class_lookup.dart';

// The dashboard owns no data: it shows what the students, courses,
// classes, agenda and audit caches already hold, and only asks for what is
// missing or stale. Coming back to it after visiting other screens is
// usually free.

/// Ensures (never forces) everything the dashboard shows.
void ensureDashboardData(BuildContext context) {
  context.read<StudentsProvider>().ensureTotal();
  context.read<CoursesProvider>().ensure();
  final teaching = context.read<TeachingProvider>();
  teaching.ensureAssignments();
  teaching.ensureAllPeriodsLoaded();
  context.read<AcademicPeriodsProvider>().ensure();
  final schedule = context.read<ScheduleProvider>();
  schedule.ensureToday();
  schedule.ensureWeek();
  context.read<AuditProvider>().ensureFeed(AuditProvider.recentQuery);
}

/// "Tus clases": the classes of the running academic period, by course
/// (all classes, newest first, while the periods aren't known or when the
/// running one has none). [academicPeriodId] is the period shown, which
/// the cards don't need to repeat.
({List<TeachingPeriodEntity> classes, int? academicPeriodId})
watchDashboardClasses(BuildContext context) {
  final all = context.watch<TeachingProvider>().allPeriods;
  final current = defaultAcademicPeriod(
    context.watch<AcademicPeriodsProvider>().all,
  );
  final inCurrent = [
    for (final p in all)
      if (p.academicPeriodId == current?.id) p,
  ];
  if (inCurrent.isEmpty) return (classes: all, academicPeriodId: null);
  return (
    classes: [
      for (final course in groupPeriodsByCourse(inCurrent)) ...course.classes,
    ],
    academicPeriodId: current!.id,
  );
}

/// Pull-to-refresh: re-reads everything the dashboard shows.
Future<void> refreshDashboardData(BuildContext context) {
  final teaching = context.read<TeachingProvider>();
  final schedule = context.read<ScheduleProvider>();
  return Future.wait([
    context.read<StudentsProvider>().refreshTotal(),
    context.read<CoursesProvider>().refresh(),
    teaching.refreshAssignments(),
    teaching.refreshPeriods(),
    schedule.refreshToday(),
    schedule.refreshWeek(),
    context.read<AuditProvider>().refreshFeed(AuditProvider.recentQuery),
  ]);
}

/// Whether every source has answered once (data or error), so the
/// dashboard can decide what to show. A refresh keeps it true.
bool watchDashboardSettled(BuildContext context) {
  bool listSettled(ListViewState<dynamic> s) =>
      s.status != ViewStatus.initial && s.status != ViewStatus.loading;
  bool detailSettled(DetailViewState<dynamic> s) =>
      s.status != DetailStatus.initial && s.status != DetailStatus.loading;

  final teaching = context.watch<TeachingProvider>();
  final schedule = context.watch<ScheduleProvider>();
  return listSettled(context.watch<StudentsProvider>().totalState) &&
      listSettled(context.watch<CoursesProvider>().state) &&
      listSettled(teaching.assignmentsState) &&
      listSettled(teaching.periodsState) &&
      listSettled(context.watch<AuditProvider>().recent) &&
      detailSettled(schedule.today) &&
      detailSettled(schedule.week);
}
