// How a course (grado + grupo) is named and ordered everywhere: entities
// of every feature build their `courseLabel` with [courseName].

/// "6° A". A group named after its grade ("10-A", "10A", "10° A" in grade
/// "10°") isn't prefixed twice: it reads "10° A"; a group named just like
/// its grade ("10") reads "10°".
String courseName(String gradeName, String groupName) {
  final grade = gradeName.trim();
  final group = groupName.trim();
  final key = _gradeKey(grade);
  final lower = group.toLowerCase();
  if (key.isNotEmpty && lower.startsWith(key)) {
    final next = lower.length > key.length ? lower[key.length] : '';
    if (!_isDigit(next)) {
      final rest = group
          .substring(key.length)
          .replaceFirst(RegExp(r'^[°º\s\-–._/]+'), '');
      return rest.isEmpty ? grade : '$grade $rest';
    }
  }
  return group.isEmpty ? grade : '$grade $group';
}

/// Natural order of grade names: by their number ("6°" before "10°",
/// "Grado 2" before "Grado 11"); names without a number (e.g. preschool,
/// "Transición") come first, alphabetically.
int compareGradeNames(String a, String b) {
  final na = _firstNumber(a);
  final nb = _firstNumber(b);
  if (na == null && nb != null) return -1;
  if (na != null && nb == null) return 1;
  if (na != null && nb != null && na != nb) return na.compareTo(nb);
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// What a group name may repeat of its grade: "10°" → "10",
/// "Transición" → "transición".
String _gradeKey(String gradeName) =>
    gradeName.replaceAll(RegExp(r'[°º]'), '').trim().toLowerCase();

bool _isDigit(String char) =>
    char.isNotEmpty && char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

int? _firstNumber(String value) {
  final match = RegExp(r'\d+').firstMatch(value);
  return match == null ? null : int.parse(match.group(0)!);
}
