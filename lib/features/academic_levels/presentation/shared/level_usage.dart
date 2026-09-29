import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../domain/entities/academic_level_entity.dart';

/// Levels in school order: by the number in their name ("5°" before
/// "10°"), then by name.
List<AcademicLevelEntity> sortLevels(List<AcademicLevelEntity> levels) {
  int? number(String name) =>
      int.tryParse(RegExp(r'\d+').firstMatch(name)?.group(0) ?? '');
  return [...levels]..sort((a, b) {
    final na = number(a.name), nb = number(b.name);
    if (na != null && nb != null && na != nb) return na.compareTo(nb);
    if (na != null && nb == null) return -1;
    if (na == null && nb != null) return 1;
    return a.name.compareTo(b.name);
  });
}

/// The badge text of a level: its number ("10") or its initials.
String levelMark(AcademicLevelEntity level) {
  final number = RegExp(r'\d+').firstMatch(level.name)?.group(0);
  if (number != null) return number;
  return level.name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}

/// The teacher's classes in each level, by level name (a class's grade is
/// the level it belongs to).
Map<String, List<TeachingPeriodEntity>> classesByLevel(
  List<TeachingPeriodEntity> classes,
) {
  final result = <String, List<TeachingPeriodEntity>>{};
  for (final c in classes) {
    (result[c.gradeName] ??= []).add(c);
  }
  return result;
}

/// Distinct courses among [classes] ("5° A, 5° B").
List<String> coursesOf(List<TeachingPeriodEntity> classes) =>
    {for (final c in classes) c.courseLabel}.toList()..sort();
