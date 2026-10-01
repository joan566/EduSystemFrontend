import '../../domain/entities/app_version_policy.dart';
import '../datasources/app_version_remote_datasource.dart';
import '../datasources/installed_version_datasource.dart';

class AppVersionRepository {
  AppVersionRepository(this._remote, this._installed);

  final AppVersionRemoteDataSource _remote;
  final InstalledVersionDataSource _installed;

  Future<AppVersionPolicy> fetchPolicy() => _remote.fetchPolicy();

  Future<InstalledApp> installedApp() => _installed.read();
}
