import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/core/network/request_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/session_fixture.dart';

void main() {
  group('foreground', () {
    late FakeBackend backend;
    late SessionFixture s;

    setUp(() {
      backend = FakeBackend();
      s = SessionFixture(backend)..createAll();
      backend.on(
        'GET',
        '/schedule/today',
        (_) => {
          'date': '2026-03-10',
          'serverTime': '2026-03-10T08:00:00',
          'classes': const [],
        },
      );
      backend.on('GET', '/subjects', (r) => pageOf([subjectJson(1, 'A')], r));
    });

    test('a short trip to the background re-reads only the agenda', () async {
      await s.schedule.ensureToday();
      await s.subjects.ensure();

      s.events.publish(const AppResumed(Duration(minutes: 1)));
      await s.schedule.ensureToday();
      await s.subjects.ensure();

      expect(backend.count('GET', '/schedule/today'), 2);
      expect(backend.count('GET', '/subjects'), 1);
    });

    test('a long one makes everything stale', () async {
      await s.subjects.ensure();
      s.events.publish(const AppResumed(Duration(minutes: 20)));
      await s.subjects.ensure();
      expect(backend.count('GET', '/subjects'), 2);
    });
  });

  group('request metrics', () {
    test('routes are normalized and never keep ids, queries or PII', () {
      expect(
        RequestMetrics.normalize(
          '/teaching-periods/12/students/7/grade-report?search=Juan',
        ),
        '/teaching-periods/{id}/students/{id}/grade-report',
      );
      final metrics = RequestMetrics()
        ..record(
          'GET',
          '/students?search=Ana',
          const Duration(milliseconds: 40),
        )
        ..record('GET', '/students', const Duration(milliseconds: 60))
        ..record(
          'PUT',
          '/exams/3',
          const Duration(milliseconds: 10),
          failed: true,
        );
      final students = metrics.routes.firstWhere((r) => r.route == '/students');
      expect(students.count, 2);
      expect(students.average, const Duration(milliseconds: 50));
      expect(metrics.totalRequests, 3);
      final report = metrics.report();
      expect(report, contains('PUT /exams/{id} ×1'));
      expect(report, contains('1 failed'));
      expect(report, isNot(contains('Ana')));
    });

    test('the interceptor counts real calls without headers', () async {
      final backend = FakeBackend();
      backend.on('GET', '/subjects', (r) => pageOf(const [], r));
      final api = backend.client();
      await api.get('/subjects', queryParameters: {'name': 'Ana'});
      await api.get('/subjects');
      expect(backend.count('GET', '/subjects'), 2);
      expect(backend.metrics.report(), isNot(contains('Ana')));
      expect(backend.metrics.report(), isNot(contains('Bearer')));
    });
  });
}
