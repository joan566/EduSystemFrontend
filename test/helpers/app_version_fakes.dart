import 'package:edusistem_front/core/utils/app_update_launcher.dart';
import 'package:edusistem_front/features/app_version/data/datasources/installed_version_datasource.dart';

const testPackageName = 'com.edusistem.test';

/// The installed build, without `package_info_plus`.
class FakeInstalledVersion implements InstalledVersionDataSource {
  FakeInstalledVersion(this.version);

  String version;
  int reads = 0;

  @override
  Future<InstalledApp> read() async {
    reads++;
    return (version: version, packageName: testPackageName);
  }
}

/// Records "Actualizar" instead of opening a store or reloading.
class FakeUpdateLauncher implements AppUpdateLauncher {
  FakeUpdateLauncher({this.isSupported = true});

  @override
  final bool isSupported;

  final List<String> opened = [];

  @override
  Future<bool> open({required String packageName}) async {
    opened.add(packageName);
    return true;
  }
}

Map<String, Object?> versionPolicyJson({
  String latest = '1.2.0',
  String minimum = '1.1.0',
}) => {'latestVersion': latest, 'minimumVersion': minimum};
