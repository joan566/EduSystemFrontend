import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/core/network/api_client.dart';
import 'package:edusistem_front/features/academic_periods/data/datasources/academic_period_remote_datasource.dart';
import 'package:edusistem_front/features/academic_periods/data/repositories/academic_period_repository.dart';
import 'package:edusistem_front/features/academic_periods/presentation/providers/academic_periods_provider.dart';
import 'package:edusistem_front/features/activities/data/datasources/activity_remote_datasource.dart';
import 'package:edusistem_front/features/activities/data/repositories/activity_repository.dart';
import 'package:edusistem_front/features/activities/presentation/providers/activities_provider.dart';
import 'package:edusistem_front/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:edusistem_front/features/attendance/data/repositories/attendance_repository.dart';
import 'package:edusistem_front/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:edusistem_front/features/audit/data/datasources/audit_remote_datasource.dart';
import 'package:edusistem_front/features/audit/presentation/providers/audit_provider.dart';
import 'package:edusistem_front/features/courses/data/datasources/course_remote_datasource.dart';
import 'package:edusistem_front/features/courses/data/repositories/course_repository.dart';
import 'package:edusistem_front/features/courses/presentation/providers/courses_provider.dart';
import 'package:edusistem_front/features/exams/data/datasources/exam_remote_datasource.dart';
import 'package:edusistem_front/features/exams/data/repositories/exam_repository.dart';
import 'package:edusistem_front/features/exams/presentation/providers/exams_provider.dart';
import 'package:edusistem_front/features/exams/presentation/providers/submissions_provider.dart';
import 'package:edusistem_front/features/grades/data/datasources/gradebook_remote_datasource.dart';
import 'package:edusistem_front/features/grades/data/datasources/grading_remote_datasource.dart';
import 'package:edusistem_front/features/grades/data/repositories/gradebook_repository.dart';
import 'package:edusistem_front/features/grades/data/repositories/grading_repository.dart';
import 'package:edusistem_front/features/grades/presentation/providers/gradebook_provider.dart';
import 'package:edusistem_front/features/grades/presentation/providers/grading_provider.dart';
import 'package:edusistem_front/features/imports/data/datasources/import_remote_datasource.dart';
import 'package:edusistem_front/features/imports/data/repositories/import_repository.dart';
import 'package:edusistem_front/features/imports/presentation/providers/imports_provider.dart';
import 'package:edusistem_front/features/schedule/data/datasources/schedule_remote_datasource.dart';
import 'package:edusistem_front/features/schedule/data/repositories/schedule_repository.dart';
import 'package:edusistem_front/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:edusistem_front/features/students/data/datasources/student_remote_datasource.dart';
import 'package:edusistem_front/features/students/data/repositories/student_repository.dart';
import 'package:edusistem_front/features/students/presentation/providers/students_provider.dart';
import 'package:edusistem_front/features/subjects/data/datasources/subject_remote_datasource.dart';
import 'package:edusistem_front/features/subjects/data/repositories/subject_repository.dart';
import 'package:edusistem_front/features/subjects/presentation/providers/subjects_provider.dart';
import 'package:edusistem_front/features/teaching/data/datasources/teaching_remote_datasource.dart';
import 'package:edusistem_front/features/teaching/data/repositories/teaching_repository.dart';
import 'package:edusistem_front/features/teaching/presentation/providers/teaching_provider.dart';

import 'fake_backend.dart';

/// Every session provider on one [FakeBackend] and one event bus, wired
/// like `sessionProviders()` in `main.dart`, so tests see the real
/// invalidation between features.
class SessionFixture {
  SessionFixture(this.backend) : api = backend.client();

  final FakeBackend backend;
  final ApiClient api;
  final DomainEvents events = DomainEvents();

  late final subjects = SubjectsProvider(
    SubjectRepository(SubjectRemoteDataSource(api)),
    events,
  );
  late final courses = CoursesProvider(
    CourseRepository(CourseRemoteDataSource(api)),
    events,
  );
  late final academicPeriods = AcademicPeriodsProvider(
    AcademicPeriodRepository(AcademicPeriodRemoteDataSource(api)),
    events,
  );
  late final teaching = TeachingProvider(
    TeachingRepository(TeachingRemoteDataSource(api)),
    events,
  );
  late final schedule = ScheduleProvider(
    ScheduleRepository(ScheduleRemoteDataSource(api)),
    events,
  );
  late final students = StudentsProvider(
    StudentRepository(StudentRemoteDataSource(api)),
    events,
  );
  late final exams = ExamsProvider(
    ExamRepository(ExamRemoteDataSource(api)),
    events,
  );
  late final submissions = SubmissionsProvider(
    ExamRepository(ExamRemoteDataSource(api)),
    events,
  );
  late final activities = ActivitiesProvider(
    ActivityRepository(ActivityRemoteDataSource(api)),
    events,
  );
  late final attendance = AttendanceProvider(
    AttendanceRepository(AttendanceRemoteDataSource(api)),
    events,
  );
  late final grading = GradingProvider(
    GradingRepository(GradingRemoteDataSource(api)),
    events,
  );
  late final gradebook = GradebookProvider(
    GradebookRepository(GradebookRemoteDataSource(api)),
    events,
  );
  late final audit = AuditProvider(AuditRemoteDataSource(api), events);
  late final imports = ImportsProvider(
    ImportRepository(ImportRemoteDataSource(api), AuditRemoteDataSource(api)),
    events,
  );

  /// Creates every provider now (they subscribe to the bus on creation, as
  /// they would in the app where they are all created with the session).
  void createAll() {
    for (final _ in [
      subjects,
      courses,
      academicPeriods,
      teaching,
      schedule,
      students,
      exams,
      submissions,
      activities,
      attendance,
      grading,
      gradebook,
      audit,
      imports,
    ]) {}
  }
}
