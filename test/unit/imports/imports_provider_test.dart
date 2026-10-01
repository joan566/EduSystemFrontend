import 'package:edusistem_front/core/errors/app_exception.dart';
import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/features/imports/data/datasources/import_remote_datasource.dart';
import 'package:edusistem_front/features/imports/data/models/import_batch_model.dart';
import 'package:edusistem_front/features/imports/data/repositories/import_repository.dart';
import 'package:edusistem_front/features/audit/data/datasources/audit_remote_datasource.dart';
import 'package:edusistem_front/features/imports/domain/entities/import_batch_entity.dart';
import 'package:edusistem_front/features/imports/presentation/providers/imports_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/session_fixture.dart';

void main() {
  late FakeBackend backend;
  late SessionFixture s;

  setUp(() {
    backend = FakeBackend();
    s = SessionFixture(backend)..createAll();
    backend.on('GET', '/imports', (r) => pageOf(const [], r));
  });

  group('model', () {
    test('a queued import has no counts yet', () {
      final batch = ImportBatchModel.fromJson(importJson(42, 'QUEUED'));
      expect(batch.status, ImportStatus.queued);
      expect(batch.type, ImportType.students);
      expect(batch.isActive, isTrue);
      expect(batch.totalRows, isNull);
      expect(batch.startedAt, isNull);
      expect(batch.progress, isNull);
    });

    test('a running import carries its progress', () {
      final batch = ImportBatchModel.fromJson(
        importJson(
          42,
          'PROCESSING',
          total: 450,
          processed: 120,
          percent: 26,
          step: 'Estudiantes',
        ),
      );
      expect(batch.processedRows, 120);
      expect(batch.currentStep, 'Estudiantes');
      expect(batch.progress, 0.26);
      // An older backend reports no progress: an indeterminate bar.
      expect(
        ImportBatchModel.fromJson(importJson(1, 'PROCESSING')).progress,
        isNull,
      );
    });

    test('a finished import carries its row errors', () {
      final result = ImportBatchModel.resultFromJson(
        importJson(
          42,
          'COMPLETED_WITH_ERRORS',
          total: 8,
          successful: 2,
          errors: const [
            {'row': 3, 'column': 'Nombres', 'message': 'Obligatorio'},
          ],
          errorsTruncated: true,
        ),
      );
      expect(result.batch.failedRows, 6);
      expect(result.batch.hasErrorReport, isTrue);
      expect(result.errors.single.column, 'Nombres');
      expect(result.errorsTruncated, isTrue);
    });

    test('a rejected file is told apart from all rows failing', () {
      final wholeFile = ImportBatchModel.fromJson(
        importJson(
          1,
          'FAILED',
          errorCode: 'MISSING_COLUMNS',
          errorMessage: 'Faltan columnas: Nombres',
        ),
      );
      final allRows = ImportBatchModel.fromJson(
        importJson(2, 'FAILED', total: 3, successful: 0),
      );
      expect(wholeFile.failedWholeFile, isTrue);
      expect(allRows.failedWholeFile, isFalse);
      expect(
        ImportBatchModel.fromJson(importJson(3, 'X', type: null)).type,
        isNull,
      );
    });
  });

  test('queued -> processing -> finished, announced once', () async {
    final answers = [
      importJson(7, 'PROCESSING'),
      importJson(7, 'COMPLETED_WITH_ERRORS', total: 4, successful: 3),
    ];
    backend.on('POST', '/imports/students', (_) => importJson(7, 'QUEUED'));
    backend.on(
      'GET',
      '/imports/{id}',
      (_) => answers.length > 1 ? answers.removeAt(0) : answers.first,
    );
    await s.imports.ensureHistory();
    final seen = recordEvents(s.events);

    final error = await s.imports.upload(
      ImportType.students,
      fileName: 'a.xlsx',
      bytes: const [1],
    );
    expect(error, isNull);
    expect(s.imports.run(ImportType.students)!.phase, ImportPhase.queued);
    expect(s.imports.hasActiveImport, isTrue);
    expect(s.imports.historyState.items.single.status, ImportStatus.queued);

    await untilImportSettles(s.imports, ImportType.students);
    final run = s.imports.run(ImportType.students)!;
    expect(run.phase, ImportPhase.finished);
    expect(run.result!.batch.successfulRows, 3);
    expect(s.imports.hasActiveImport, isFalse);
    expect(
      s.imports.historyState.items.single.status,
      ImportStatus.completedWithErrors,
    );
    await pumpEventQueue();
    expect(seen.whereType<SessionDataReset>(), hasLength(1));

    // Stopped polling once finished.
    final polls = backend.count('GET', '/imports/{id}');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(backend.count('GET', '/imports/{id}'), polls);
  });

  test('any finished import re-reads the whole session', () async {
    backend.on(
      'POST',
      '/imports/teaching-periods/{id}',
      (_) => importJson(8, 'QUEUED', type: 'TEACHING_PERIOD'),
    );
    backend.on(
      'GET',
      '/imports/{id}',
      (_) => importJson(
        8,
        'COMPLETED',
        type: 'TEACHING_PERIOD',
        total: 2,
        successful: 2,
      ),
    );
    final seen = recordEvents(s.events);

    await s.imports.upload(
      ImportType.teachingPeriod,
      fileName: 'a.xlsx',
      bytes: const [1],
      teachingPeriodId: 5,
    );
    await untilImportSettles(s.imports, ImportType.teachingPeriod);
    await pumpEventQueue();

    expect(seen.whereType<SessionDataReset>(), hasLength(1));
  });

  test('a rejected file shows its message and changes nothing', () async {
    backend.on('POST', '/imports/students', (_) => importJson(9, 'QUEUED'));
    backend.on(
      'GET',
      '/imports/{id}',
      (_) => importJson(
        9,
        'FAILED',
        errorCode: 'INVALID_EXCEL',
        errorMessage: 'El archivo está dañado.',
      ),
    );
    final seen = recordEvents(s.events);

    await s.imports.upload(
      ImportType.students,
      fileName: 'a.xlsx',
      bytes: const [1],
    );
    await untilImportSettles(s.imports, ImportType.students);
    await pumpEventQueue();

    final batch = s.imports.run(ImportType.students)!.result!.batch;
    expect(batch.failedWholeFile, isTrue);
    expect(batch.errorMessage, 'El archivo está dañado.');
    expect(seen, isEmpty);
  });

  test('IMPORT_IN_PROGRESS follows the import already running', () async {
    backend.on(
      'POST',
      '/imports/students',
      (_) => throw const FakeHttpError(409, AppErrorCode.importInProgress),
    );
    backend.on(
      'GET',
      '/imports',
      (r) => pageOf([importJson(3, 'PROCESSING', type: 'SCHOOL_SETUP')], r),
    );
    backend.on(
      'GET',
      '/imports/{id}',
      (_) => importJson(3, 'PROCESSING', type: 'SCHOOL_SETUP'),
    );

    final error = await s.imports.upload(
      ImportType.students,
      fileName: 'a.xlsx',
      bytes: const [1],
    );
    expect(error?.code, AppErrorCode.importInProgress);
    expect(s.imports.run(ImportType.students), isNull);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(s.imports.run(ImportType.schoolSetup)?.isActive, isTrue);
    expect(backend.count('GET', '/imports/{id}'), greaterThan(0));
    s.imports.dispose();
  });

  test('an import still running when the screen opens is resumed', () async {
    backend.on('GET', '/imports', (r) => pageOf([importJson(4, 'QUEUED')], r));
    backend.on(
      'GET',
      '/imports/{id}',
      (_) => importJson(4, 'COMPLETED', total: 1, successful: 1),
    );

    await s.imports.ensureHistory();
    expect(s.imports.run(ImportType.students)?.phase, ImportPhase.queued);
    await untilImportSettles(s.imports, ImportType.students);
    expect(s.imports.run(ImportType.students)!.phase, ImportPhase.finished);
  });

  test('progress is followed while it advances', () async {
    var processed = 0;
    backend.on('POST', '/imports/students', (_) => importJson(6, 'QUEUED'));
    backend.on('GET', '/imports/{id}', (_) {
      processed++;
      if (processed > 12) {
        return importJson(6, 'COMPLETED', total: 12, successful: 12);
      }
      return importJson(
        6,
        'PROCESSING',
        total: 12,
        processed: processed,
        percent: processed * 100 ~/ 12,
        step: 'Estudiantes',
      );
    });
    final imports = _provider(s, stallTimeout: const Duration(milliseconds: 5));

    await imports.upload(
      ImportType.students,
      fileName: 'a.xlsx',
      bytes: const [1],
    );
    final seenProgress = <double?>[];
    imports.addListener(() {
      final run = imports.run(ImportType.students);
      if (run?.phase == ImportPhase.processing) {
        seenProgress.add(run!.batch!.progress);
        expect(imports.activeImport?.type, ImportType.students);
      }
    });
    await untilImportSettles(imports, ImportType.students);

    // Longer than the stall timeout overall, but never stalled.
    expect(imports.run(ImportType.students)!.phase, ImportPhase.finished);
    expect(seenProgress.first, closeTo(1 / 12, 0.01));
    expect(seenProgress.last, 1.0);
    expect(imports.activeImport, isNull);
    imports.dispose();
  });

  test('an import given up on is announced once it is seen finished', () async {
    var finished = false;
    backend.on('POST', '/imports/students', (_) => importJson(6, 'QUEUED'));
    backend.on(
      'GET',
      '/imports/{id}',
      (_) => finished
          ? importJson(6, 'COMPLETED', total: 1, successful: 1)
          : importJson(6, 'PROCESSING'),
    );
    backend.on(
      'GET',
      '/imports',
      (r) => pageOf([
        finished
            ? importJson(6, 'COMPLETED', total: 1, successful: 1)
            : importJson(6, 'PROCESSING'),
      ], r),
    );
    final imports = _provider(s, stallTimeout: const Duration(milliseconds: 5));
    final seen = recordEvents(s.events);

    await imports.upload(
      ImportType.students,
      fileName: 'a.xlsx',
      bytes: const [1],
    );
    await untilImportSettles(imports, ImportType.students);
    expect(imports.run(ImportType.students)!.phase, ImportPhase.timedOut);

    finished = true;
    await imports.ensureHistory(); // e.g. back on the import screen
    await untilImportSettles(imports, ImportType.students);
    await pumpEventQueue();
    expect(imports.run(ImportType.students)!.phase, ImportPhase.finished);
    expect(seen.whereType<SessionDataReset>(), hasLength(1));
    imports.dispose();
  });

  test('polling gives up when the import stops advancing', () async {
    final imports = _provider(s, stallTimeout: const Duration(milliseconds: 5));
    backend.on('POST', '/imports/students', (_) => importJson(6, 'QUEUED'));
    backend.on('GET', '/imports/{id}', (_) => importJson(6, 'PROCESSING'));

    await imports.upload(
      ImportType.students,
      fileName: 'a.xlsx',
      bytes: const [1],
    );
    await untilImportSettles(imports, ImportType.students);
    expect(imports.run(ImportType.students)!.phase, ImportPhase.timedOut);
    // The first read (QUEUED -> PROCESSING) is progress; 5 more find it
    // where it was.
    expect(backend.count('GET', '/imports/{id}'), 6);
    imports.dispose();
  });

  test('ending the session stops polling', () async {
    backend.on('POST', '/imports/students', (_) => importJson(5, 'QUEUED'));
    backend.on('GET', '/imports/{id}', (_) => importJson(5, 'PROCESSING'));

    await s.imports.upload(
      ImportType.students,
      fileName: 'a.xlsx',
      bytes: const [1],
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    s.imports.dispose();
    final polls = backend.count('GET', '/imports/{id}');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(backend.count('GET', '/imports/{id}'), lessThanOrEqualTo(polls + 1));
  });
}

ImportsProvider _provider(SessionFixture s, {required Duration stallTimeout}) =>
    ImportsProvider(
      ImportRepository(
        ImportRemoteDataSource(s.api),
        AuditRemoteDataSource(s.api),
      ),
      s.events,
      pollInterval: const Duration(milliseconds: 1),
      stallTimeout: stallTimeout,
    );
