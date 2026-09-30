import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/core/state/list_state.dart';
import 'package:edusistem_front/features/courses/data/datasources/course_remote_datasource.dart';
import 'package:edusistem_front/features/courses/data/repositories/course_repository.dart';
import 'package:edusistem_front/features/courses/presentation/providers/courses_provider.dart';
import 'package:edusistem_front/features/subjects/data/datasources/subject_remote_datasource.dart';
import 'package:edusistem_front/features/subjects/data/repositories/subject_repository.dart';
import 'package:edusistem_front/features/subjects/presentation/providers/subjects_provider.dart';
import 'package:edusistem_front/features/teaching/data/datasources/teaching_remote_datasource.dart';
import 'package:edusistem_front/features/teaching/data/repositories/teaching_repository.dart';
import 'package:edusistem_front/features/teaching/presentation/providers/teaching_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late DomainEvents events;

  setUp(() {
    backend = FakeBackend();
    events = DomainEvents();
  });

  TeachingProvider teaching() => TeachingProvider(
    TeachingRepository(TeachingRemoteDataSource(backend.client())),
    events,
  );

  SubjectsProvider subjects() => SubjectsProvider(
    SubjectRepository(SubjectRemoteDataSource(backend.client())),
    events,
  );

  CoursesProvider courses() => CoursesProvider(
    CourseRepository(CourseRemoteDataSource(backend.client())),
    events,
  );

  group('teaching periods', () {
    final all = [for (var i = 1; i <= 230; i++) periodJson(i)];

    setUp(() => backend.on('GET', '/teaching-periods', (r) => pageOf(all, r)));

    test('reads every page, not just page 0', () async {
      final provider = teaching();
      await provider.ensureAllPeriodsLoaded();

      expect(provider.allPeriods, hasLength(230));
      // 230 classes in pages of 100 (the API's maximum).
      expect(backend.count('GET', '/teaching-periods'), 3);
      expect(backend.log.first, 'GET /teaching-periods');
    });

    test('concurrent and repeated ensures share one read', () async {
      final provider = teaching();
      // The Clases page, its preview and the dashboard all ask at once.
      await Future.wait([
        provider.ensureAllPeriodsLoaded(),
        provider.ensureAllPeriodsLoaded(),
        provider.ensureAllPeriodsLoaded(),
      ]);
      await provider.ensureAllPeriodsLoaded();
      expect(
        backend.count('GET', '/teaching-periods'),
        3,
        reason: '3 pages once',
      );
    });

    test('class detail comes from the catalog without its own GET', () async {
      final provider = teaching();
      await provider.ensurePeriodDetail(7);
      expect(provider.periodDetail(7).data?.id, 7);
      expect(backend.count('GET', '/teaching-periods/{id}'), 0);
    });

    test('create and delete update the catalog locally', () async {
      backend.on('POST', '/teaching-periods', (_) => periodJson(999));
      backend.on('DELETE', '/teaching-periods/{id}', (_) => null);
      final provider = teaching();
      await provider.ensureAllPeriodsLoaded();
      final seen = recordEvents(events);

      expect(
        await provider.createPeriod(
          teachingAssignmentId: 1,
          academicPeriodId: 1,
        ),
        isNull,
      );
      expect(provider.allPeriods.map((p) => p.id), contains(999));

      expect(await provider.deletePeriod(3), isNull);
      expect(provider.allPeriods.map((p) => p.id), isNot(contains(3)));

      expect(
        backend.count('GET', '/teaching-periods'),
        3,
        reason: 'no GET after POST/DELETE',
      );
      expect(seen.whereType<CatalogChanged>(), hasLength(2));
    });
  });

  group('assignments', () {
    test('toggling active is optimistic and rolls back on failure', () async {
      backend.on(
        'GET',
        '/teaching-assignments',
        (r) => pageOf([assignmentJson(1)], r),
      );
      backend.on(
        'PATCH',
        '/teaching-assignments/{id}/active',
        (_) => throw const FakeHttpError(409, 'CONFLICT'),
      );
      final provider = teaching();
      await provider.ensureAssignments();

      final pending = provider.setAssignmentActive(1, false);
      expect(provider.allAssignments.single.active, isFalse, reason: 'at once');
      final error = await pending;
      expect(error, isNotNull);
      expect(
        provider.allAssignments.single.active,
        isTrue,
        reason: 'rolled back',
      );
      expect(backend.count('GET', '/teaching-assignments'), 1);
    });

    test('filters apply in memory', () async {
      backend.on(
        'GET',
        '/teaching-assignments',
        (r) => pageOf([assignmentJson(1), assignmentJson(2, active: false)], r),
      );
      final provider = teaching();
      await provider.ensureAssignments();
      expect(provider.assignments(active: true).items, hasLength(1));
      expect(provider.assignments(subjectId: 102).items.single.id, 2);
      expect(backend.count('GET', '/teaching-assignments'), 1);
    });
  });

  group('subjects', () {
    var store = <Map<String, Object?>>[];

    setUp(() {
      store = [subjectJson(1, 'Biología'), subjectJson(2, 'Química')];
      backend.on('GET', '/subjects', (r) => pageOf(store, r));
      backend.on(
        'POST',
        '/subjects',
        (r) => subjectJson(3, (r.data as Map)['name'] as String),
      );
      backend.on(
        'PUT',
        '/subjects/{id}',
        (r) => subjectJson(1, (r.data as Map)['name'] as String),
      );
      backend.on('DELETE', '/subjects/{id}', (_) => null);
    });

    test('create, update and delete apply locally with no GET', () async {
      final provider = subjects();
      await provider.ensure();
      expect(backend.count('GET', '/subjects'), 1);

      await provider.create(name: 'Artes');
      // Inserted where the API would list it (by name).
      expect(provider.all.map((s) => s.name), ['Artes', 'Biología', 'Química']);

      await provider.update(1, name: 'Zoología');
      expect(provider.all.last.name, 'Zoología');

      await provider.delete(2);
      expect(provider.all.map((s) => s.id), [3, 1]);

      expect(backend.count('GET', '/subjects'), 1, reason: 'no re-reads');
      expect(backend.count('POST', '/subjects'), 1);
      expect(backend.count('PUT', '/subjects/{id}'), 1);
      expect(backend.count('DELETE', '/subjects/{id}'), 1);
    });

    test('search and paging happen in memory', () async {
      store = [
        for (var i = 0; i < 45; i++) subjectJson(i, 'Materia $i'),
        subjectJson(99, 'Matemáticas'),
      ];
      final provider = subjects();
      await provider.ensure();

      expect(provider.query(search: 'matematicas').items.single.id, 99);
      final second = provider.query(page: 1);
      expect(second.page, 1);
      expect(second.totalPages, 3);
      expect(second.totalElements, 46);
      expect(provider.query(search: 'zzz').status, ViewStatus.empty);
      expect(backend.count('GET', '/subjects'), 1);
    });

    test('forms see the whole catalog whatever the screen filters', () async {
      store = [for (var i = 0; i < 45; i++) subjectJson(i, 'Materia $i')];
      final provider = subjects();
      await provider.ensure();
      provider.query(search: 'Materia 1', page: 0);
      expect(provider.all, hasLength(45));
    });
  });

  group('invalidation between catalogs', () {
    setUp(() {
      backend.on('GET', '/teaching-periods', (r) => pageOf([periodJson(1)], r));
      backend.on('GET', '/groups', (r) => pageOf([courseJson(1)], r));
      backend.on('PUT', '/groups/{id}', (_) => courseJson(1, name: 'B'));
      backend.on('POST', '/subjects', (_) => subjectJson(5, 'Nueva'));
      backend.on('GET', '/subjects', (r) => pageOf(const [], r));
    });

    test(
      'renaming a course makes the classes (which embed it) stale',
      () async {
        final classes = teaching();
        final catalog = courses();
        await Future.wait([classes.ensureAllPeriodsLoaded(), catalog.ensure()]);

        await catalog.update(1, name: 'B', academicYear: 2026);
        expect(catalog.all.single.name, 'B');
        expect(
          backend.count('GET', '/teaching-periods'),
          1,
          reason: 'no eager GET',
        );

        await classes.ensureAllPeriodsLoaded();
        expect(
          backend.count('GET', '/teaching-periods'),
          2,
          reason: 're-read on demand',
        );
        expect(backend.count('GET', '/groups'), 1);
      },
    );

    test('creating a subject does not invalidate classes', () async {
      final classes = teaching();
      final catalog = subjects();
      await Future.wait([classes.ensureAllPeriodsLoaded(), catalog.ensure()]);
      await catalog.create(name: 'Nueva');
      await classes.ensureAllPeriodsLoaded();
      expect(backend.count('GET', '/teaching-periods'), 1);
    });
  });
}
