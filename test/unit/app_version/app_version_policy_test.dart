import 'package:edusistem_front/features/app_version/data/models/app_version_policy_model.dart';
import 'package:edusistem_front/features/app_version/domain/entities/app_version_policy.dart';
import 'package:edusistem_front/features/app_version/domain/entities/semantic_version.dart';
import 'package:flutter_test/flutter_test.dart';

SemanticVersion v(String raw) => SemanticVersion.tryParse(raw)!;

void main() {
  group('minimum 1.1.0, latest 1.2.0', () {
    final policy = AppVersionPolicy(latest: v('1.2.0'), minimum: v('1.1.0'));

    const expected = {
      '1.0.0': AppVersionStatus.updateRequired,
      '1.0.5': AppVersionStatus.updateRequired,
      '1.1.0': AppVersionStatus.updateAvailable,
      '1.1.5': AppVersionStatus.updateAvailable,
      '1.2.0': AppVersionStatus.current,
      '1.3.0': AppVersionStatus.current,
      '1.2.0+5': AppVersionStatus.current,
    };
    expected.forEach((installed, status) {
      test('$installed → ${status.name}', () {
        expect(policy.statusFor(v(installed)), status);
      });
    });
  });

  test('minimum == latest: below is required, at it is current', () {
    final policy = AppVersionPolicy(latest: v('1.1.0'), minimum: v('1.1.0'));
    expect(policy.statusFor(v('1.0.9')), AppVersionStatus.updateRequired);
    expect(policy.statusFor(v('1.1.0')), AppVersionStatus.current);
  });

  test('latest < minimum is an invalid policy, never a corrected one', () {
    expect(
      () => AppVersionPolicy(latest: v('1.0.0'), minimum: v('1.1.0')),
      throwsFormatException,
    );
  });

  group('AppVersionPolicyModel.fromJson', () {
    test('parses a valid policy', () {
      final policy = AppVersionPolicyModel.fromJson({
        'latestVersion': '1.10.0',
        'minimumVersion': '1.9.0',
      });
      expect(policy.latest, v('1.10.0'));
      expect(policy.minimum, v('1.9.0'));
    });

    for (final (name, json) in <(String, Object?)>[
      ('latest < minimum', {'latestVersion': '1.0.0', 'minimumVersion': '1.1.0'}),
      ('missing minimumVersion', {'latestVersion': '1.2.0'}),
      ('missing latestVersion', {'minimumVersion': '1.1.0'}),
      ('non-string version', {'latestVersion': 2, 'minimumVersion': '1.1.0'}),
      ('invalid version', {'latestVersion': '1.2', 'minimumVersion': '1.1.0'}),
      ('pre-release', {'latestVersion': '1.2.0-beta', 'minimumVersion': '1.1.0'}),
      ('not an object', 'oops'),
      ('null', null),
    ]) {
      test('rejects $name', () {
        expect(() => AppVersionPolicyModel.fromJson(json), throwsFormatException);
      });
    }
  });
}
