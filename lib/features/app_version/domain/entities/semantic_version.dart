/// A strict `X.Y.Z` version, the format the backend's version policy uses.
///
/// Components compare numerically (`1.10.0 > 1.9.0`), never as strings.
class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static final _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

  /// Parses `X.Y.Z`. Flutter's build number (`1.2.0+5`) is dropped first and
  /// never takes part in comparisons. Anything else — fewer or more
  /// components, signs, letters, pre-release tags (`1.2.0-beta`) — is not a
  /// version and returns null.
  static SemanticVersion? tryParse(String raw) {
    final plus = raw.indexOf('+');
    final core = (plus == -1 ? raw : raw.substring(0, plus)).trim();
    final match = _pattern.firstMatch(core);
    if (match == null) return null;
    final parts = [
      for (var i = 1; i <= 3; i++) int.tryParse(match.group(i)!),
    ];
    if (parts.contains(null)) return null;
    return SemanticVersion(parts[0]!, parts[1]!, parts[2]!);
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;
  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is SemanticVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
