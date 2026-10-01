import '../config/app_config.dart';
import 'app_update_launcher_io.dart'
    if (dart.library.js_interop) 'app_update_launcher_web.dart'
    as platform;

/// Where "Actualizar" takes the user, per platform:
///
/// - Android: the Google Play listing (`market://`, then the https page),
///   or [AppConfig.updateUrl] when configured.
/// - Web: a reload, which serves the newly deployed build.
/// - Other platforms (Linux): no update channel, so [isSupported] is false
///   and the version check is skipped there.
///
/// This is the only seam a future Google Play In-App Update (flexible or
/// immediate) has to replace; the version policy and UI don't change.
class AppUpdateLauncher {
  const AppUpdateLauncher();

  bool get isSupported => platform.updateSupported;

  /// Opens the update for the installed [packageName]. False when nothing
  /// could be opened.
  Future<bool> open({required String packageName}) => platform.openUpdate(
    packageName: packageName,
    overrideUrl: AppConfig.updateUrl,
  );
}
