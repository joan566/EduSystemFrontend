import 'package:edusistem_front/core/theme/app_theme.dart';
import 'package:edusistem_front/features/app_version/data/datasources/installed_version_datasource.dart';
import 'package:edusistem_front/features/app_version/data/models/app_version_policy_model.dart';
import 'package:edusistem_front/features/app_version/data/repositories/app_version_repository.dart';
import 'package:edusistem_front/features/app_version/domain/entities/app_version_policy.dart';
import 'package:edusistem_front/features/app_version/presentation/pages/app_version_gate.dart';
import 'package:edusistem_front/features/app_version/presentation/providers/app_version_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/app_version_fakes.dart';

/// Answers a policy without HTTP (the HTTP path is covered by the provider
/// test); null makes the check fail.
class _FakeRepository implements AppVersionRepository {
  _FakeRepository(this.installed);

  String installed;
  Map<String, Object?>? policy = versionPolicyJson();

  @override
  Future<AppVersionPolicy> fetchPolicy() async {
    final json = policy;
    if (json == null) throw const FormatException('offline');
    return AppVersionPolicyModel.fromJson(json);
  }

  @override
  Future<InstalledApp> installedApp() async =>
      (version: installed, packageName: testPackageName);
}

const _phone = Size(400, 800);
const _desktop = Size(1280, 800);

void main() {
  late FakeUpdateLauncher launcher;
  late _FakeRepository repository;
  late AppVersionProvider provider;
  late GoRouter router;

  setUp(() {
    launcher = FakeUpdateLauncher();
  });

  /// The real app's wiring: the gate in `MaterialApp.router`'s builder,
  /// around a router with a home and a second screen.
  Future<void> pumpApp(
    WidgetTester tester, {
    required String installed,
    Size size = _phone,
    Map<String, Object?>? policy,
    bool failCheck = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = _FakeRepository(installed);
    if (policy != null) repository.policy = policy;
    if (failCheck) repository.policy = null;
    provider = AppVersionProvider(repository: repository, launcher: launcher);
    addTearDown(provider.dispose);
    await provider.check();

    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/other',
          builder: (_, _) => const Scaffold(body: Text('Otra pantalla')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppVersionProvider>.value(
        value: provider,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          builder: (_, child) => AppVersionGate(child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CURRENT', () {
    testWidgets('shows the app, nothing else', (tester) async {
      await pumpApp(tester, installed: '1.2.0');
      expect(provider.status, AppVersionStatus.current);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Actualizar'), findsNothing);
      expect(find.text('Continuar'), findsNothing);
    });
  });

  group('could not check', () {
    testWidgets('the app runs normally', (tester) async {
      await pumpApp(tester, installed: '1.0.0', failCheck: true);
      expect(provider.status, isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Actualizar'), findsNothing);
    });
  });

  for (final (name, size) in [('phone', _phone), ('desktop', _desktop)]) {
    group('UPDATE_AVAILABLE ($name)', () {
      testWidgets('offers Actualizar and Continuar over the app', (
        tester,
      ) async {
        await pumpApp(tester, installed: '1.1.0', size: size);
        expect(find.text('Hay una nueva versión de EduSistem'), findsOneWidget);
        expect(find.text('Actualizar'), findsOneWidget);
        expect(find.text('Continuar'), findsOneWidget);
        expect(find.text('1.1.0'), findsOneWidget);
        expect(find.text('1.2.0'), findsOneWidget);
      });

      testWidgets('Continuar lets the user carry on', (tester) async {
        await pumpApp(tester, installed: '1.1.0', size: size);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(find.text('Hay una nueva versión de EduSistem'), findsNothing);
        expect(find.text('Home'), findsOneWidget);
        router.go('/other');
        await tester.pumpAndSettle();
        expect(find.text('Otra pantalla'), findsOneWidget);
      });

      testWidgets('Actualizar opens the update', (tester) async {
        await pumpApp(tester, installed: '1.1.0', size: size);
        await tester.tap(find.text('Actualizar'));
        await tester.pumpAndSettle();
        expect(launcher.opened, [testPackageName]);
        expect(find.text('Home'), findsOneWidget);
      });
    });

    group('UPDATE_REQUIRED ($name)', () {
      testWidgets('replaces the app; only Actualizar', (tester) async {
        await pumpApp(tester, installed: '1.0.0', size: size);

        expect(find.text('Home'), findsNothing);
        expect(find.text('Actualiza EduSistem para continuar'), findsOneWidget);
        expect(find.text('Versión instalada'), findsOneWidget);
        expect(find.text('1.0.0'), findsOneWidget);
        expect(find.text('Versión mínima'), findsOneWidget);
        expect(find.text('1.1.0'), findsOneWidget);
        expect(find.text('Actualizar'), findsOneWidget);
        expect(find.text('Continuar'), findsNothing);
        expect(find.text('Omitir'), findsNothing);
        expect(find.text('Ahora no'), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      });

      testWidgets('navigation cannot get past it', (tester) async {
        await pumpApp(tester, installed: '1.0.0', size: size);

        router.go('/other');
        await tester.pumpAndSettle();
        expect(find.text('Otra pantalla'), findsNothing);
        expect(find.text('Home'), findsNothing);

        // System back: nothing to pop into.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsNothing);
        expect(find.text('Otra pantalla'), findsNothing);
        expect(find.text('Actualiza EduSistem para continuar'), findsOneWidget);
      });

      testWidgets('Actualizar opens the update and the block stays', (
        tester,
      ) async {
        await pumpApp(tester, installed: '1.0.0', size: size);
        await tester.tap(find.text('Actualizar'));
        await tester.pumpAndSettle();
        expect(launcher.opened, [testPackageName]);
        expect(find.text('Home'), findsNothing);
        expect(find.text('Actualiza EduSistem para continuar'), findsOneWidget);
      });
    });
  }

  testWidgets('a later check that finds the version too old blocks a user '
      'already inside the app', (tester) async {
    await pumpApp(
      tester,
      installed: '1.1.0',
      policy: versionPolicyJson(latest: '1.1.0', minimum: '1.0.0'),
    );
    router.go('/other');
    await tester.pumpAndSettle();
    expect(find.text('Otra pantalla'), findsOneWidget);

    repository.policy = versionPolicyJson(latest: '1.3.0', minimum: '1.2.0');
    await provider.check();
    await tester.pumpAndSettle();

    expect(find.text('Otra pantalla'), findsNothing);
    expect(find.text('Actualiza EduSistem para continuar'), findsOneWidget);
    expect(find.text('Continuar'), findsNothing);
  });
}
