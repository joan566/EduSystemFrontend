import 'package:package_info_plus/package_info_plus.dart';

/// What the platform reports about the running build.
typedef InstalledApp = ({String version, String packageName});

/// The installed build, from `package_info_plus` (Android `versionName`,
/// the web build's `version.json`, ...). `version` is the pubspec's `X.Y.Z`;
/// the build number is not part of it.
class InstalledVersionDataSource {
  const InstalledVersionDataSource();

  Future<InstalledApp> read() async {
    final info = await PackageInfo.fromPlatform();
    return (version: info.version, packageName: info.packageName);
  }
}
