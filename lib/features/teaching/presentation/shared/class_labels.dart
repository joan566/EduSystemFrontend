import '../../../../core/utils/course_naming.dart';
import '../../domain/entities/teaching_period_entity.dart';

export '../../../../core/utils/course_naming.dart';

// How a course (grado + grupo) and a class are named across the app, in
// one place: only what tells two items apart is shown.

/// Labels of several courses, by group id: the academic year is added only
/// where two courses would otherwise read the same ("6° A (2025)").
Map<int, String> courseLabels(
  Iterable<
    ({int groupId, String gradeName, String groupName, int academicYear})
  >
  courses,
) {
  final byGroup = {for (final c in courses) c.groupId: c};
  final names = {
    for (final c in byGroup.values)
      c.groupId: courseName(c.gradeName, c.groupName),
  };
  final counts = <String, int>{};
  for (final name in names.values) {
    counts[name] = (counts[name] ?? 0) + 1;
  }
  return {
    for (final MapEntry(key: id, value: name) in names.entries)
      id: counts[name]! > 1 ? '$name (${byGroup[id]!.academicYear})' : name,
  };
}

/// "Matemáticas · 6° A".
String classTitle(String subjectName, String courseLabel) =>
    '$subjectName · $courseLabel';

/// A class's full name. The academic period is added only when it isn't
/// [currentAcademicPeriodId] (the one the screen is about), so classes of
/// the running period don't carry it in every row.
String classLabel(
  TeachingPeriodEntity period, {
  int? currentAcademicPeriodId,
  String? courseLabel,
}) {
  final title = courseLabel == null
      ? period.title
      : classTitle(period.subjectName, courseLabel);
  return period.academicPeriodId == currentAcademicPeriodId
      ? title
      : '$title (${period.academicPeriodName})';
}
