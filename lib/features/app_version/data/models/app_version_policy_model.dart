import '../../domain/entities/app_version_policy.dart';
import '../../domain/entities/semantic_version.dart';

class AppVersionPolicyModel {
  /// Throws [FormatException] when a field is missing, is not a string, is
  /// not `X.Y.Z`, or the policy itself is invalid (`latest < minimum`): a
  /// partial or corrected policy is never built.
  static AppVersionPolicy fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Version policy is not a JSON object.');
    }
    return AppVersionPolicy(
      latest: _version(json, 'latestVersion'),
      minimum: _version(json, 'minimumVersion'),
    );
  }

  static SemanticVersion _version(Map<String, dynamic> json, String field) {
    final raw = json[field];
    final version = raw is String ? SemanticVersion.tryParse(raw) : null;
    if (version == null) {
      throw FormatException('Invalid "$field" in version policy: $raw');
    }
    return version;
  }
}
