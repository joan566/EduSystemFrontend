import 'package:flutter/foundation.dart';

import '../../../audit/presentation/providers/audit_provider.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';

/// Orchestrates the parallel loads the dashboard needs from other
/// features' own providers (§93: no separate dashboard datasource
/// duplicating what students/courses/teaching/audit already fetch — only
/// their `totalElements`, a handful of recent rows, today's classes and
/// the coming week's are needed here).
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    required StudentsProvider students,
    required CoursesProvider courses,
    required TeachingProvider teaching,
    required AuditProvider audit,
    required ScheduleProvider schedule,
  }) : _students = students,
       _courses = courses,
       _teaching = teaching,
       _audit = audit,
       _schedule = schedule;

  final StudentsProvider _students;
  final CoursesProvider _courses;
  final TeachingProvider _teaching;
  final AuditProvider _audit;
  final ScheduleProvider _schedule;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> loadAll() async {
    await Future.wait([
      _students.load(page: 0),
      _courses.load(page: 0),
      _teaching.loadAssignments(active: true),
      _teaching.loadPeriods(page: 0),
      _audit.load(page: 0),
      _schedule.loadToday(),
      _schedule.loadWeek(),
    ]);
    _loaded = true;
    notifyListeners();
  }
}
