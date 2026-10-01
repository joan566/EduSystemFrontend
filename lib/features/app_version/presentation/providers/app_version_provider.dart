import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/app_update_launcher.dart';
import '../../data/repositories/app_version_repository.dart';
import '../../domain/entities/app_version_policy.dart';
import '../../domain/entities/semantic_version.dart';

/// Whether the installed version is still usable, for the whole app run.
///
/// App-level (outside `SessionScope`): the policy is public and the same for
/// every user, so login, logout and user changes never reset it.
///
/// Two outcomes must not be confused:
/// - **Could not check** (no network, timeout, backend down, 4xx/5xx,
///   malformed or invalid policy, unreadable installed version): fail-open.
///   [status] keeps whatever was last known (null when nothing was) and the
///   check is retried on the next return to the foreground.
/// - **Checked and too old** (`installed < minimum`):
///   [AppVersionStatus.updateRequired], a hard block. A later failed check
///   never lifts it; only a successful check can change it.
class AppVersionProvider extends ChangeNotifier with WidgetsBindingObserver {
  AppVersionProvider({
    required AppVersionRepository repository,
    AppUpdateLauncher launcher = const AppUpdateLauncher(),
    bool enabled = AppConfig.versionCheckEnabled,
    DateTime Function() clock = DateTime.now,
  }) : _repository = repository,
       _launcher = launcher,
       _enabled = enabled && launcher.isSupported,
       _clock = clock {
    if (_enabled) WidgetsBinding.instance.addObserver(this);
  }

  final AppVersionRepository _repository;
  final AppUpdateLauncher _launcher;
  final bool _enabled;
  final DateTime Function() _clock;

  AppVersionStatus? _status;
  SemanticVersion? _installed;
  AppVersionPolicy? _policy;
  String? _packageName;
  bool _optionalDismissed = false;

  // Internal only: the UI never reacts to "checking" or "failed".
  Future<void>? _inFlight;
  bool _lastCheckFailed = false;
  DateTime? _checkedAt;
  bool _disposed = false;

  /// Null until a check succeeds (or on platforms without update channel):
  /// the app runs normally.
  AppVersionStatus? get status => _status;

  SemanticVersion? get installedVersion => _installed;
  SemanticVersion? get latestVersion => _policy?.latest;
  SemanticVersion? get minimumVersion => _policy?.minimum;

  /// The optional-update notice, shown at most once per launch.
  bool get showOptionalPrompt =>
      _status == AppVersionStatus.updateAvailable && !_optionalDismissed;

  /// Reads the installed version and the backend's policy. Concurrent calls
  /// share one request.
  Future<void> check() {
    if (!_enabled) return Future.value();
    return _inFlight ??= _check().whenComplete(() => _inFlight = null);
  }

  Future<void> _check() async {
    try {
      final app = await _repository.installedApp();
      final installed = SemanticVersion.tryParse(app.version);
      if (installed == null) {
        throw FormatException('Installed version is not X.Y.Z: ${app.version}');
      }
      final policy = await _repository.fetchPolicy();
      if (_disposed) return;
      _installed = installed;
      _packageName = app.packageName;
      _policy = policy;
      _status = policy.statusFor(installed);
      _lastCheckFailed = false;
      _checkedAt = _clock();
      notifyListeners();
    } on Exception catch (e) {
      // AppException (network, HTTP errors), FormatException (malformed or
      // invalid policy, unreadable installed version), PlatformException
      // (package info).
      _failed(e);
    }
  }

  /// Could not check: keeps the last known [status] untouched.
  void _failed(Object error) {
    _lastCheckFailed = true;
    if (kDebugMode) debugPrint('[AppVersion] check failed: $error');
  }

  /// "Continuar" on the optional notice. Only meaningful for
  /// [AppVersionStatus.updateAvailable]; nothing dismisses a required update.
  void dismissOptional() {
    if (_status != AppVersionStatus.updateAvailable) return;
    _optionalDismissed = true;
    notifyListeners();
  }

  /// "Actualizar": Google Play on Android, a reload on the web. The optional
  /// notice closes; the required block stays until a newer build runs.
  Future<void> openUpdate() async {
    final packageName = _packageName;
    if (packageName == null) return;
    if (_status == AppVersionStatus.updateAvailable) dismissOptional();
    await _launcher.open(packageName: packageName);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shouldRecheck) check();
  }

  /// Back in the foreground (including from Google Play): check again if the
  /// last attempt failed, while blocked, or when the result is old.
  bool get _shouldRecheck {
    final checkedAt = _checkedAt;
    return _lastCheckFailed ||
        _status == AppVersionStatus.updateRequired ||
        checkedAt == null ||
        _clock().difference(checkedAt) >= AppConfig.versionRecheckAfter;
  }

  @override
  void dispose() {
    _disposed = true;
    if (_enabled) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
