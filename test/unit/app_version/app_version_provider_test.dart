import 'package:dio/dio.dart';
import 'package:edusistem_front/core/storage/token_storage.dart';
import 'package:edusistem_front/features/app_version/data/datasources/app_version_remote_datasource.dart';
import 'package:edusistem_front/features/app_version/data/repositories/app_version_repository.dart';
import 'package:edusistem_front/features/app_version/domain/entities/app_version_policy.dart';
import 'package:edusistem_front/features/app_version/domain/entities/semantic_version.dart';
import 'package:edusistem_front/features/app_version/presentation/providers/app_version_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_version_fakes.dart';
import '../../helpers/fake_backend.dart';

const _route = '/app/version';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBackend backend;
  late FakeInstalledVersion installed;
  late FakeUpdateLauncher launcher;
  late DateTime now;

  /// What the endpoint answers; a handler may throw to fail.
  late Object? Function(RequestOptions) answer;

  setUp(() {
    backend = FakeBackend();
    installed = FakeInstalledVersion('1.2.0');
    launcher = FakeUpdateLauncher();
    now = DateTime(2026, 10, 1, 8);
    answer = (_) => versionPolicyJson();
    backend.on('GET', _route, (r) => answer(r));
  });

  AppVersionProvider build({bool enabled = true}) {
    final provider = AppVersionProvider(
      repository: AppVersionRepository(
        AppVersionRemoteDataSource(backend.client()),
        installed,
      ),
      launcher: launcher,
      enabled: enabled,
      clock: () => now,
    );
    addTearDown(provider.dispose);
    return provider;
  }

  Future<AppVersionStatus?> statusFor(String version) async {
    installed.version = version;
    final provider = build();
    await provider.check();
    return provider.status;
  }

  group('a successful check (minimum 1.1.0, latest 1.2.0)', () {
    test('1.0.0 → updateRequired', () async {
      expect(await statusFor('1.0.0'), AppVersionStatus.updateRequired);
    });

    test('1.1.0 → updateAvailable', () async {
      expect(await statusFor('1.1.0'), AppVersionStatus.updateAvailable);
    });

    test('1.1.5 → updateAvailable', () async {
      expect(await statusFor('1.1.5'), AppVersionStatus.updateAvailable);
    });

    test('1.2.0 → current', () async {
      expect(await statusFor('1.2.0'), AppVersionStatus.current);
    });

    test('1.2.0+5 → current (build number ignored)', () async {
      expect(await statusFor('1.2.0+5'), AppVersionStatus.current);
    });

    test('exposes the versions the UI shows', () async {
      installed.version = '1.0.0+3';
      final provider = build();
      await provider.check();
      expect(provider.installedVersion, const SemanticVersion(1, 0, 0));
      expect(provider.minimumVersion, const SemanticVersion(1, 1, 0));
      expect(provider.latestVersion, const SemanticVersion(1, 2, 0));
    });
  });

  test('/app/version is sent without Authorization, even in a session',
      () async {
    final api = backend.client();
    await api.setSession(
      AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    Object? authorization = 'not sent';
    answer = (r) {
      authorization = r.headers['Authorization'];
      return versionPolicyJson();
    };
    final provider = AppVersionProvider(
      repository: AppVersionRepository(
        AppVersionRemoteDataSource(api),
        installed,
      ),
      launcher: launcher,
    );
    addTearDown(provider.dispose);

    await provider.check();

    expect(authorization, isNull);
    expect(provider.status, AppVersionStatus.current);
  });

  group('could not check → status null (fail-open)', () {
    final failures = <String, Object? Function(RequestOptions)>{
      'network error': (_) => throw Exception('offline'),
      '500': (_) => throw const FakeHttpError(500, 'INTERNAL_ERROR'),
      'incomplete JSON': (_) => {'latestVersion': '1.2.0'},
      'not a JSON object': (_) => 'oops',
      'invalid version format': (_) => versionPolicyJson(latest: '1.2'),
      'invalid policy (latest < minimum)': (_) =>
          versionPolicyJson(latest: '1.0.0', minimum: '1.1.0'),
    };
    failures.forEach((name, failure) {
      test(name, () async {
        answer = failure;
        installed.version = '1.0.0'; // would be required if it were known
        final provider = build();
        await provider.check();
        expect(provider.status, isNull);
        expect(provider.showOptionalPrompt, isFalse);
      });
    });

    test('404 (endpoint missing)', () async {
      backend = FakeBackend(); // no route registered
      final provider = build();
      await provider.check();
      expect(backend.count('GET', _route), 1);
      expect(provider.status, isNull);
    });

    test('invalid installed version: the backend is not even asked', () async {
      installed.version = 'dev';
      final provider = build();
      await provider.check();
      expect(provider.status, isNull);
      expect(backend.count('GET', _route), 0);
    });
  });

  test('concurrent checks share one request', () async {
    final gate = backend.hold('GET', _route);
    final provider = build();
    final first = provider.check();
    final second = provider.check();
    gate.complete();
    await Future.wait([first, second]);
    expect(backend.count('GET', _route), 1);
    expect(provider.status, AppVersionStatus.current);
  });

  test('a failed check is retried and then resolves', () async {
    answer = (_) => throw Exception('offline');
    final provider = build();
    await provider.check();
    expect(provider.status, isNull);

    answer = (_) => versionPolicyJson();
    await provider.check();
    expect(provider.status, AppVersionStatus.current);
  });

  test('a failed re-check never lifts a known updateRequired', () async {
    installed.version = '1.0.0';
    final provider = build();
    await provider.check();
    expect(provider.status, AppVersionStatus.updateRequired);

    for (final failure in <Object? Function(RequestOptions)>[
      (_) => throw Exception('offline'),
      (_) => throw const FakeHttpError(503),
      (_) => {'broken': true},
    ]) {
      answer = failure;
      await provider.check();
      expect(provider.status, AppVersionStatus.updateRequired);
    }
  });

  test('a later check that finds the version too old blocks it', () async {
    installed.version = '1.1.0';
    answer = (_) => versionPolicyJson(latest: '1.1.0', minimum: '1.0.0');
    final provider = build();
    await provider.check();
    expect(provider.status, AppVersionStatus.current);

    answer = (_) => versionPolicyJson(latest: '1.3.0', minimum: '1.2.0');
    await provider.check();
    expect(provider.status, AppVersionStatus.updateRequired);
  });

  group('back in the foreground', () {
    void resume(AppVersionProvider p) =>
        p.didChangeAppLifecycleState(AppLifecycleState.resumed);

    test('re-checks only after a failure, while blocked or after 6 h',
        () async {
      final provider = build();
      await provider.check();
      expect(backend.count('GET', _route), 1);

      now = now.add(const Duration(hours: 5));
      resume(provider);
      await pumpEventQueue();
      expect(backend.count('GET', _route), 1, reason: 'fresh result');

      now = now.add(const Duration(hours: 1));
      resume(provider);
      await pumpEventQueue();
      expect(backend.count('GET', _route), 2, reason: '6 h old');
    });

    test('after a failed check', () async {
      answer = (_) => throw Exception('offline');
      final provider = build();
      await provider.check();
      answer = (_) => versionPolicyJson();

      resume(provider);
      await pumpEventQueue();
      expect(provider.status, AppVersionStatus.current);
    });

    test('while updateRequired (e.g. back from Google Play)', () async {
      installed.version = '1.0.0';
      final provider = build();
      await provider.check();

      resume(provider);
      await pumpEventQueue();
      expect(backend.count('GET', _route), 2);
      expect(provider.status, AppVersionStatus.updateRequired);
    });
  });

  group('optional update', () {
    test('dismissOptional() hides the notice for this launch', () async {
      installed.version = '1.1.0';
      final provider = build();
      await provider.check();
      expect(provider.showOptionalPrompt, isTrue);

      provider.dismissOptional();
      expect(provider.showOptionalPrompt, isFalse);
      expect(provider.status, AppVersionStatus.updateAvailable);

      await provider.check();
      expect(provider.showOptionalPrompt, isFalse);
    });

    test('dismissOptional() cannot dismiss a required update', () async {
      installed.version = '1.0.0';
      final provider = build();
      await provider.check();
      provider.dismissOptional();
      expect(provider.status, AppVersionStatus.updateRequired);
    });

    test('openUpdate() opens the installed package and closes the notice',
        () async {
      installed.version = '1.1.0';
      final provider = build();
      await provider.check();
      await provider.openUpdate();
      expect(launcher.opened, [testPackageName]);
      expect(provider.showOptionalPrompt, isFalse);
    });
  });

  test('disabled (or no update channel): nothing is checked', () async {
    final provider = build(enabled: false);
    await provider.check();
    expect(provider.status, isNull);
    expect(installed.reads, 0);
    expect(backend.count('GET', _route), 0);

    launcher = FakeUpdateLauncher(isSupported: false);
    final unsupported = build();
    await unsupported.check();
    expect(backend.count('GET', _route), 0);
  });
}
