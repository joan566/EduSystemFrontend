import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/features/audit/data/datasources/audit_remote_datasource.dart';
import 'package:edusistem_front/features/imports/data/datasources/import_remote_datasource.dart';
import 'package:edusistem_front/features/imports/data/models/import_batch_model.dart';
import 'package:edusistem_front/features/imports/data/repositories/import_repository.dart';
import 'package:edusistem_front/features/imports/domain/entities/import_batch_entity.dart';
import 'package:edusistem_front/features/imports/presentation/desktop/desktop_import_indicator.dart';
import 'package:edusistem_front/features/imports/presentation/mobile/mobile_import_banner.dart';
import 'package:edusistem_front/features/imports/presentation/providers/imports_provider.dart';
import 'package:edusistem_front/features/imports/presentation/shared/import_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_backend.dart';
import '../helpers/session_fixture.dart';

/// Imports whose student run the test sets directly.
class _Imports extends ImportsProvider {
  _Imports(SessionFixture s)
    : super(
        ImportRepository(
          ImportRemoteDataSource(s.api),
          AuditRemoteDataSource(s.api),
        ),
        DomainEvents(),
      );

  ImportRun? _run;

  void set(ImportRun? run) {
    _run = run;
    notifyListeners();
  }

  @override
  ImportRun? run(ImportType type) => type == ImportType.students ? _run : null;

  @override
  ({ImportType type, ImportRun run})? get activeImport =>
      _run != null && _run!.isActive
      ? (type: ImportType.students, run: _run!)
      : null;
}

void main() {
  testWidgets('the shell shows a running import everywhere but its own '
      'screen, and tells when it finishes', (tester) async {
    final imports = _Imports(SessionFixture(FakeBackend()));
    final router = GoRouter(
      initialLocation: '/app/home',
      routes: [
        ShellRoute(
          builder: (context, state, child) => ImportCompletionListener(
            child: Scaffold(
              body: Column(
                children: [
                  Expanded(child: child),
                  const MobileImportBanner(),
                  const DesktopImportIndicator(),
                ],
              ),
            ),
          ),
          routes: [
            GoRoute(path: '/app/home', builder: (_, _) => const Text('home')),
            GoRoute(path: '/app/data', builder: (_, _) => const Text('data')),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ImportsProvider>.value(
        value: imports,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.textContaining('Importando'), findsNothing);

    imports.set(
      ImportRun(
        phase: ImportPhase.processing,
        batch: ImportBatchModel.fromJson(
          importJson(
            1,
            'PROCESSING',
            total: 450,
            processed: 120,
            percent: 26,
            step: 'Estudiantes',
          ),
        ),
      ),
    );
    await tester.pump();
    // Banner (mobile) and pill (desktop).
    expect(
      find.text('Importando Estudiantes · 120 de 450 filas'),
      findsNWidgets(2),
    );
    expect(find.text('26%'), findsNWidgets(2));

    router.go('/app/data');
    await tester.pumpAndSettle();
    expect(find.textContaining('Importando'), findsNothing);

    router.go('/app/home');
    await tester.pumpAndSettle();
    final result = ImportBatchModel.resultFromJson(
      importJson(1, 'COMPLETED', total: 450, successful: 450),
    );
    imports.set(
      ImportRun(
        phase: ImportPhase.finished,
        batch: result.batch,
        result: result,
      ),
    );
    await tester.pump();
    expect(find.textContaining('Importando'), findsNothing);
    expect(find.text('Importación completada: 450 filas.'), findsOneWidget);
  });
}
