import 'semantic_version.dart';

/// Where the installed version stands against the backend's policy.
enum AppVersionStatus {
  /// At or above [AppVersionPolicy.latest]: nothing to show.
  current,

  /// Compatible but older than the latest release: optional update.
  updateAvailable,

  /// Below [AppVersionPolicy.minimum]: no longer compatible. The app is
  /// blocked until the user updates.
  updateRequired,
}

/// The backend's version policy (`GET /app/version`).
///
/// Only valid when `minimum <= latest`. The backend guarantees it; a policy
/// breaking it is rejected here instead of being "fixed" on the client, so
/// an instance of this class is always a valid policy.
class AppVersionPolicy {
  AppVersionPolicy({required this.latest, required this.minimum}) {
    if (latest < minimum) {
      throw FormatException(
        'Invalid version policy: latestVersion $latest is below '
        'minimumVersion $minimum.',
      );
    }
  }

  final SemanticVersion latest;

  /// The oldest version still compatible with the backend.
  final SemanticVersion minimum;

  AppVersionStatus statusFor(SemanticVersion installed) {
    if (installed < minimum) return AppVersionStatus.updateRequired;
    if (installed < latest) return AppVersionStatus.updateAvailable;
    return AppVersionStatus.current;
  }
}
