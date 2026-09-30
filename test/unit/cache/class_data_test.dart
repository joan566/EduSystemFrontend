import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/core/state/list_state.dart';
import 'package:edusistem_front/features/attendance/domain/entities/attendance_entity.dart';
import 'package:edusistem_front/features/audit/presentation/providers/audit_provider.dart';
import 'package:edusistem_front/features/schedule/domain/entities/schedule_entities.dart';
import 'package:edusistem_front/features/students/domain/entities/student_entity.dart';
import 'package:edusistem_front/features/students/presentation/providers/students_provider.dart';
import 'package:edusistem_front/features/students/presentation/shared/student_grades_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/session_fixture.dart';

void main() {
  late FakeBackend backend;
  late SessionFixture s;

  setUp(() {
    backend = FakeBackend();
    s = SessionFixture(backend)..createAll();
  });

  /// Class 1 and class 2 exist; per-class resources answer for any class.
  void serveClasses() {
    backend.on(
      'GET',
      '/teaching-periods',
      (r) => pageOf([
        periodJson(1, groupId: 10),
        periodJson(2, groupId: 20),
        periodJson(3, groupId: 10),
      ], r),
    );
    backend.on(
      'GET',
      '/teaching-periods/{id}/summary',
      (r) => summaryJson(int.parse(r.path.split('/')[2])),
    );
    backend.on(
      'GET',
      '/teaching-periods/{id}/period-grades',
      (r) => periodGradesJson(int.parse(r.path.split('/')[2]), [1, 2, 3]),
    );
  }

  group('exams per class', () {
    setUp(() {
      serveClasses();
      backend.on('GET', '/exams', (r) {
        final tp = int.parse('${r.queryParameters['teachingPeriodId']}');
        return pageOf([
          examJson(10 * tp + 1, teachingPeriodId: tp),
          examJson(10 * tp + 2, teachingPeriodId: tp),
        ], r);
      });
      backend.on(
        'POST',
        '/exams',
        (r) => examJson(
          99,
          teachingPeriodId: (r.data as Map)['teachingPeriodId'] as int,
          name: 'Nuevo',
          date: '2026-05-01T08:00:00',
        ),
      );
      backend.on(
        'PUT',
        '/exams/{id}',
        (r) => examJson(11, name: (r.data as Map)['name'] as String),
      );
      backend.on('DELETE', '/exams/{id}', (_) => null);
    });

    test('each class keeps its own list (screens never overwrite)', () async {
      await s.exams.ensureExams(1);
      await s.exams.ensureExams(2);
      expect(s.exams.exams(1).items.map((e) => e.id), [11, 12]);
      expect(s.exams.exams(2).items.map((e) => e.id), [21, 22]);

      // Coming back to either class reads nothing.
      await s.exams.ensureExams(1);
      await s.exams.ensureExams(2);
      expect(backend.count('GET', '/exams'), 2);
    });

    test('create inserts, update patches, delete removes — no GET', () async {
      await s.exams.ensureExams(1);

      final created = await s.exams.create(
        teachingPeriodId: 1,
        name: 'Nuevo',
        numberOfQuestions: 10,
      );
      expect(created?.id, 99);
      // Newest date first, like the API.
      expect(s.exams.exams(1).items.first.id, 99);
      expect(s.exams.detail(99).data?.name, 'Nuevo');

      await s.exams.updateMetadata(11, name: 'Renombrado');
      expect(
        s.exams.exams(1).items.firstWhere((e) => e.id == 11).name,
        'Renombrado',
      );
      expect(s.exams.detail(11).data?.name, 'Renombrado');

      await s.exams.delete(12);
      expect(s.exams.exams(1).items.map((e) => e.id), [99, 11]);

      expect(backend.count('GET', '/exams'), 1);
      expect(backend.count('GET', '/exams/{id}'), 0);
    });

    test('a new exam makes the class summary and grades stale', () async {
      await s.teaching.ensurePeriodSummary(1);
      await s.teaching.ensurePeriodSummary(2);
      await s.grading.ensurePeriodGrades(1);
      await s.exams.create(
        teachingPeriodId: 1,
        name: 'N',
        numberOfQuestions: 5,
      );

      // Nothing re-read eagerly...
      expect(backend.count('GET', '/teaching-periods/{id}/summary'), 2);
      // ...but on demand, only for the class that changed.
      await s.teaching.ensurePeriodSummary(1);
      await s.teaching.ensurePeriodSummary(2);
      await s.grading.ensurePeriodGrades(1);
      expect(backend.count('GET', '/teaching-periods/{id}/summary'), 3);
      expect(backend.count('GET', '/teaching-periods/{id}/period-grades'), 2);
    });
  });

  group('activities', () {
    setUp(() {
      serveClasses();
      backend.on(
        'GET',
        '/activities',
        (r) => pageOf([activityJson(1), activityJson(2)], r),
      );
      backend.on(
        'GET',
        '/activities/{id}/grades',
        (_) => [activityGradeJson(1, null), activityGradeJson(2, 3)],
      );
      backend.on(
        'PUT',
        '/activities/{id}/grades',
        (_) => [activityGradeJson(1, 4.5), activityGradeJson(2, 3)],
      );
      backend.on(
        'GET',
        '/teaching-periods/{id}/students/{id}/grade-report',
        (r) => reportJson(1, 1),
      );
    });

    test('detail comes from the class list with no GET', () async {
      await s.activities.ensureActivities(1);
      await s.activities.ensureDetail(2);
      expect(s.activities.detail(2).data?.name, 'Taller 2');
      expect(backend.count('GET', '/activities/{id}'), 0);
    });

    test(
      'saving grades writes locally and invalidates exactly its class',
      () async {
        await s.activities.ensureActivities(1);
        await s.activities.ensureGrades(1);
        await s.grading.ensurePeriodGrades(1);
        await s.grading.ensurePeriodGrades(2);
        await s.gradebook.ensureReport(1, 1);
        await s.teaching.ensurePeriodSummary(1);

        await s.activities.saveGrades(1, [
          (studentId: 1, grade: 4.5, comment: null),
        ]);
        expect(s.activities.grades(1).items.first.grade, 4.5);
        expect(backend.count('GET', '/activities/{id}/grades'), 1);

        await Future.wait([
          s.grading.ensurePeriodGrades(1),
          s.grading.ensurePeriodGrades(2),
          s.gradebook.ensureReport(1, 1),
          s.teaching.ensurePeriodSummary(1),
        ]);
        // Class 1's grades, report and summary re-read; class 2's not.
        expect(backend.count('GET', '/teaching-periods/{id}/period-grades'), 3);
        expect(
          backend.count(
            'GET',
            '/teaching-periods/{id}/students/{id}/grade-report',
          ),
          2,
        );
        expect(backend.count('GET', '/teaching-periods/{id}/summary'), 2);
      },
    );
  });

  group('attendance', () {
    var sessionCreated = false;

    setUp(() {
      sessionCreated = false;
      serveClasses();
      backend.on('GET', '/attendance-sessions/day', (r) {
        return {
          'session': null,
          'students': [recordJson(1, null), recordJson(2, null)],
        };
      });
      backend.on(
        'GET',
        '/attendance-sessions',
        (r) => pageOf([sessionJson(1, '2026-03-01')], r),
      );
      backend.on('POST', '/attendance-sessions', (_) {
        sessionCreated = true;
        return sessionJson(7, '2026-03-10');
      });
      backend.on(
        'PUT',
        '/attendance-sessions/{id}/records',
        (_) => {
          'session': sessionJson(7, '2026-03-10'),
          'students': [recordJson(1, 'PRESENT'), recordJson(2, 'ABSENT')],
        },
      );
    });

    test('a date already opened costs nothing; another date is read', () async {
      final day1 = DateTime(2026, 3, 10);
      await s.attendance.ensureDay(1, day1);
      await s.attendance.ensureDay(1, DateTime(2026, 3, 11));
      await s.attendance.ensureDay(1, day1);
      expect(backend.count('GET', '/attendance-sessions/day'), 2);
    });

    test('saving creates the session and updates locally', () async {
      final day = DateTime(2026, 3, 10);
      await s.attendance.ensureSessions(1);
      await s.attendance.ensureDay(1, day);
      await s.teaching.ensurePeriodSummary(1);

      final error = await s.attendance.saveDay(1, day, [
        (studentId: 1, status: AttendanceStatus.present, observation: null),
        (studentId: 2, status: AttendanceStatus.absent, observation: null),
      ]);
      expect(error, isNull);
      expect(sessionCreated, isTrue);
      expect(s.attendance.day(1, day).data?.session?.id, 7);
      expect(
        s.attendance.day(1, day).data?.students.first.status,
        AttendanceStatus.present,
      );
      // The new day is in the class's sessions, newest first.
      expect(s.attendance.sessions(1).items.first.id, 7);
      expect(s.attendance.sessions(1).totalElements, 2);
      expect(backend.count('GET', '/attendance-sessions'), 1);
      expect(backend.count('GET', '/attendance-sessions/day'), 1);

      await s.teaching.ensurePeriodSummary(1);
      expect(backend.count('GET', '/teaching-periods/{id}/summary'), 2);
    });
  });

  group('schedule', () {
    test(
      'a block change re-reads that class and makes the agenda stale',
      () async {
        backend.on(
          'GET',
          '/teaching-periods/{id}/schedules',
          (_) => [
            {
              'id': 1,
              'teachingPeriodId': 1,
              'dayOfWeek': 'MONDAY',
              'startTime': '08:00',
              'endTime': '09:00',
              'room': null,
            },
          ],
        );
        backend.on('POST', '/teaching-periods/{id}/schedules', (_) => null);
        backend.on(
          'GET',
          '/schedule/today',
          (_) => {
            'date': '2026-03-10',
            'serverTime': '2026-03-10T08:00:00',
            'classes': const [],
          },
        );
        await s.schedule.ensureClassSchedules(1);
        await s.schedule.ensureToday();

        await s.schedule.saveClassSchedule(
          1,
          dayOfWeek: 2,
          startTime: const ClockTime(10, 0),
          endTime: const ClockTime(11, 0),
        );
        // Only the class's blocks were re-read (the POST answers nothing).
        expect(backend.count('GET', '/teaching-periods/{id}/schedules'), 2);
        expect(backend.count('GET', '/schedule/today'), 1);
        await s.schedule.ensureToday();
        expect(backend.count('GET', '/schedule/today'), 2);
      },
    );
  });

  group('students', () {
    setUp(() {
      serveClasses();
      backend.on(
        'GET',
        '/students',
        (r) => pageOf([studentJson(1), studentJson(2)], r),
      );
      backend.on('POST', '/students/{id}/groups/{id}/withdrawal', (_) => null);
    });

    test('each exact query is cached; a different one is read', () async {
      final all = StudentsProvider.queryOf();
      final search = StudentsProvider.queryOf(groupId: 10, search: ' juan ');
      await s.students.ensureQuery(all);
      await s.students.ensureQuery(search);
      await s.students.ensureQuery(all);
      await s.students.ensureQuery(
        StudentsProvider.queryOf(groupId: 10, search: 'juan'),
      );
      expect(backend.count('GET', '/students'), 2);
    });

    test('the total never downloads the list', () async {
      await s.students.ensureTotal();
      expect(s.students.totalStudents, 2);
      expect(backend.log.single, 'GET /students');
    });

    test('withdrawal invalidates listings, rosters and grades', () async {
      final all = StudentsProvider.queryOf();
      await s.students.ensureQuery(all);
      await s.students.ensureGroupRoster(10);
      await s.grading.ensurePeriodGrades(1);

      await s.students.withdraw(1, 10);
      await s.students.ensureQuery(all);
      await s.students.ensureGroupRoster(10);
      await s.grading.ensurePeriodGrades(1);
      expect(backend.count('GET', '/students'), 4);
      expect(backend.count('GET', '/teaching-periods/{id}/period-grades'), 2);
    });
  });

  group('student grades (no N+1)', () {
    StudentDetailEntity detailFor(int id) => StudentDetailEntity(
      student: StudentEntity(
        id: id,
        studentCode: 'E$id',
        identificationNumber: '$id',
        firstName: 'Ana',
        lastName: 'Pérez',
        email: '',
      ),
      enrollments: [
        StudentEnrollmentEntity(
          groupId: 10,
          groupName: 'A',
          gradeName: '5°',
          academicYear: 2026,
          enrolledAt: DateTime(2026, 1, 1),
          active: true,
        ),
      ],
    );

    test("one read per class serves every student's grades", () async {
      serveClasses();
      final first = StudentGradesController(
        teaching: s.teaching,
        grading: s.grading,
      );
      await first.ensureLoaded(detailFor(1));
      // Group 10 has classes 1 and 3.
      expect(first.grades?.map((g) => g.period.id), unorderedEquals([1, 3]));
      expect(first.grades?.every((g) => g.grade?.studentId == 1), isTrue);
      expect(backend.count('GET', '/teaching-periods/{id}/period-grades'), 2);

      // Another student of the same classes (the desktop preview walking
      // the table): no new request at all.
      for (final id in [2, 3]) {
        final next = StudentGradesController(
          teaching: s.teaching,
          grading: s.grading,
        );
        await next.ensureLoaded(detailFor(id));
        expect(next.grades?.first.grade?.studentId, id);
        next.dispose();
      }
      expect(backend.count('GET', '/teaching-periods/{id}/period-grades'), 2);
      expect(backend.count('GET', '/teaching-periods'), 1);
      first.dispose();
    });
  });

  group('gradebook', () {
    test('saving an observation patches the report without a GET', () async {
      serveClasses();
      backend.on(
        'GET',
        '/teaching-periods/{id}/students/{id}/grade-report',
        (_) => reportJson(1, 5),
      );
      backend.on(
        'PUT',
        '/teaching-periods/{id}/students/{id}/observation',
        (r) => {'text': (r.data as Map)['text'], 'updatedAt': null},
      );
      await s.gradebook.ensureReport(1, 5);
      await s.gradebook.saveObservation(1, 5, 'Muy bien');
      expect(s.gradebook.report(1, 5).data?.observation?.text, 'Muy bien');
      await s.gradebook.ensureReport(1, 5);
      expect(
        backend.count(
          'GET',
          '/teaching-periods/{id}/students/{id}/grade-report',
        ),
        1,
      );
    });

    test(
      'an activity grade re-reads only its detail, then marks the rest stale',
      () async {
        serveClasses();
        backend.on(
          'GET',
          '/evaluations/{id}/students/{id}/grade-detail',
          (_) => gradeDetailJson(1, 701, 5),
        );
        backend.on('PUT', '/activities/{id}/grades/{id}', (_) => null);
        backend.on(
          'GET',
          '/activities/{id}/grades',
          (_) => [activityGradeJson(5, 4)],
        );
        backend.on('GET', '/activities', (r) => pageOf([activityJson(1)], r));
        await s.gradebook.ensureDetail(701, 5);
        await s.activities.ensureActivities(1);
        await s.activities.ensureGrades(1);
        await s.grading.ensurePeriodGrades(1);

        final detail = s.gradebook.detail(701, 5).data!;
        await s.gradebook.saveActivityGrade(detail, grade: 4);
        // The PUT answers nothing: only the detail is re-read.
        expect(
          backend.count('GET', '/evaluations/{id}/students/{id}/grade-detail'),
          2,
        );
        // The activity's grade sheet and the class grades are stale now.
        await s.activities.ensureGrades(1);
        await s.grading.ensurePeriodGrades(1);
        expect(backend.count('GET', '/activities/{id}/grades'), 2);
        expect(backend.count('GET', '/teaching-periods/{id}/period-grades'), 2);
      },
    );
  });

  group('imports', () {
    test('school setup marks every cache stale', () async {
      serveClasses();
      backend.on('GET', '/subjects', (r) => pageOf([subjectJson(1, 'A')], r));
      backend.on('GET', '/imports', (r) => pageOf(const [], r));
      backend.on(
        'POST',
        '/imports/school-setup',
        (_) => {
          'id': 1,
          'status': 'COMPLETED',
          'totalRows': 1,
          'successfulRows': 1,
          'failedRows': 0,
          'errors': const [],
        },
      );
      await s.subjects.ensure();
      await s.teaching.ensureAllPeriodsLoaded();
      final seen = recordEvents(s.events);

      await s.imports.uploadSchoolSetup(fileName: 'x.xlsx', bytes: const [1]);
      expect(seen.whereType<SessionDataReset>(), hasLength(1));

      await s.subjects.ensure();
      await s.teaching.ensureAllPeriodsLoaded();
      expect(backend.count('GET', '/subjects'), 2);
      expect(backend.count('GET', '/teaching-periods'), 2);
    });
  });

  group('audit', () {
    test(
      'any mutation makes the feed stale; nothing re-read eagerly',
      () async {
        serveClasses();
        backend.on('GET', '/audit-logs', (r) => pageOf(const [], r));
        backend.on('POST', '/subjects', (_) => subjectJson(1, 'Nueva'));
        await s.audit.ensureFeed(AuditProvider.recentQuery);
        await s.audit.ensureFeed(AuditProvider.recentQuery);
        expect(backend.count('GET', '/audit-logs'), 1);

        await s.subjects.create(name: 'Nueva');
        expect(backend.count('GET', '/audit-logs'), 1);
        await s.audit.ensureFeed(AuditProvider.recentQuery);
        expect(backend.count('GET', '/audit-logs'), 2);
        expect(s.audit.recent.status, ViewStatus.empty);
      },
    );
  });
}
