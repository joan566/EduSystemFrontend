import 'package:edusistem_front/features/audit/presentation/providers/audit_provider.dart';
import 'package:edusistem_front/features/students/presentation/providers/students_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/session_fixture.dart';

/// Serves a small school for [teacher]: every name carries the teacher, so
/// a test can prove nothing of one appears in the other's session.
void serveSchool(FakeBackend backend, String teacher) {
  final offset = teacher == 'A' ? 0 : 100;
  backend.on(
    'GET',
    '/teaching-periods',
    (r) => pageOf([
      periodJson(offset + 1, groupId: offset + 10, subject: 'Clase $teacher'),
      periodJson(offset + 2, groupId: offset + 10, subject: 'Clase $teacher'),
    ], r),
  );
  backend.on(
    'GET',
    '/teaching-assignments',
    (r) => pageOf([assignmentJson(offset + 1)], r),
  );
  backend.on(
    'GET',
    '/subjects',
    (r) => pageOf([subjectJson(offset + 1, 'Materia $teacher')], r),
  );
  backend.on(
    'GET',
    '/groups',
    (r) => pageOf([courseJson(offset + 10, name: 'Curso $teacher')], r),
  );
  backend.on('GET', '/academic-periods', (r) => pageOf(const [], r));
  backend.on(
    'GET',
    '/students',
    (r) => pageOf([studentJson(offset + 1, lastName: 'De $teacher')], r),
  );
  backend.on('GET', '/audit-logs', (r) => pageOf(const [], r));
  backend.on(
    'GET',
    '/schedule/today',
    (_) => {
      'date': '2026-03-10',
      'serverTime': '2026-03-10T08:00:00',
      'classes': const [],
    },
  );
  backend.on(
    'GET',
    '/schedule',
    (_) => {
      'from': '2026-03-10',
      'to': '2026-03-16',
      'serverTime': '2026-03-10T08:00:00',
      'days': const [],
    },
  );
  backend.on('GET', '/teaching-periods/{id}/schedules', (_) => const []);
  backend.on(
    'GET',
    '/exams',
    (r) => pageOf([
      examJson(
        offset + 1,
        teachingPeriodId: int.parse('${r.queryParameters['teachingPeriodId']}'),
        name: 'Examen $teacher',
      ),
    ], r),
  );
  backend.on('GET', '/activities', (r) => pageOf(const [], r));
  backend.on(
    'GET',
    '/teaching-periods/{id}/summary',
    (r) => summaryJson(int.parse(r.path.split('/')[2])),
  );
}

/// What each screen's `ensureData` asks for (see the pages).
Future<void> dashboard(SessionFixture s) => Future.wait([
  s.students.ensureTotal(),
  s.courses.ensure(),
  s.teaching.ensureAssignments(),
  s.teaching.ensureAllPeriodsLoaded(),
  s.schedule.ensureToday(),
  s.schedule.ensureWeek(),
  s.audit.ensureFeed(AuditProvider.recentQuery),
]);

Future<void> clases(SessionFixture s) => Future.wait([
  s.subjects.ensure(),
  s.courses.ensure(),
  s.schedule.ensureWeek(),
  s.teaching.ensureAssignments(),
  s.teaching.ensureAllPeriodsLoaded(),
  s.academicPeriods.ensure(),
]);

Future<void> classDetail(SessionFixture s, int id) async {
  await Future.wait([
    s.schedule.ensureClassSchedules(id),
    s.exams.ensureExams(id),
    s.activities.ensureActivities(id),
    s.audit.ensureClassLogs(id),
    s.teaching.ensurePeriodSummary(id),
    s.teaching.ensurePeriodDetail(id),
  ]);
  final period = s.teaching.periodDetail(id).data!;
  await s.students.ensureGroupRoster(period.groupId);
}

Future<void> examenes(SessionFixture s) async {
  await s.teaching.ensureAllPeriodsLoaded();
  await s.exams.ensureExams(s.teaching.allPeriods.first.id);
}

Future<void> estudiantes(SessionFixture s) => Future.wait([
  s.students.ensureQuery(StudentsProvider.queryOf()),
  s.teaching.ensureAllPeriodsLoaded(),
]);

Future<void> walk(SessionFixture s) async {
  final firstClass = (await () async {
    await s.teaching.ensureAllPeriodsLoaded();
    return s.teaching.allPeriods.first.id;
  }());
  await dashboard(s);
  await clases(s);
  await classDetail(s, firstClass);
  await examenes(s);
  await classDetail(s, firstClass); // volver (didPopNext)
  await estudiantes(s);
  await dashboard(s);
}

void main() {
  test(
    'the route reads only what it lacks; repeating it reads nothing',
    () async {
      final backend = FakeBackend();
      serveSchool(backend, 'A');
      final s = SessionFixture(backend)..createAll();

      await walk(s);
      final first = backend.total;
      // Dashboard 7 + Clases 2 (subjects, academic periods) + class detail 6
      // (blocks, exams, activities, class audit, summary, roster) + Exámenes 0
      // + volver 0 + Estudiantes 1 + Dashboard 0. Before: 28.
      expect(first, 16, reason: backend.metrics.report());

      await walk(s);
      expect(backend.total, first, reason: 'the second walk is all memory');
    },
  );

  test('after logout, teacher B sees nothing of teacher A', () async {
    final backendA = FakeBackend();
    serveSchool(backendA, 'A');
    final a = SessionFixture(backendA)..createAll();
    await walk(a);
    expect(a.teaching.allPeriods.first.subjectName, contains('Clase A'));

    // Logout = the session's providers are disposed (SessionScope); B's
    // session is built from scratch.
    for (final p in [a.teaching, a.subjects, a.courses, a.students, a.exams]) {
      p.dispose();
    }
    final backendB = FakeBackend();
    serveSchool(backendB, 'B');
    final b = SessionFixture(backendB)..createAll();
    expect(b.teaching.allPeriods, isEmpty);
    expect(b.subjects.all, isEmpty);
    await walk(b);

    String everything() => [
      ...b.teaching.allPeriods.map((p) => p.subjectName),
      ...b.subjects.all.map((x) => x.name),
      ...b.courses.all.map((c) => c.name),
      ...b.students
          .query(StudentsProvider.queryOf())
          .items
          .map((x) => x.lastName),
      ...b.exams.exams(b.teaching.allPeriods.first.id).items.map((e) => e.name),
    ].join(' | ');
    expect(everything(), isNot(contains(' A')));
    expect(everything(), contains('Clase B'));
    expect(backendA.total, greaterThan(0));
    // Every id B's session asked for is one of B's (A's are all < 100).
    final ids = [
      for (final line in backendB.log)
        for (final match in RegExp(r'/(\d+)').allMatches(line))
          int.parse(match.group(1)!),
    ];
    expect(ids, isNotEmpty);
    expect(
      ids.every((id) => id >= 100),
      isTrue,
      reason: backendB.log.join('\n'),
    );
  });
}
