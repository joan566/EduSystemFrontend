import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';
import 'class_labels.dart';
import 'class_lookup.dart';

/// A subject the teacher teaches in a course, with its class in the chosen
/// academic period ([period] is null when that class doesn't exist yet).
class ClassEntry {
  const ClassEntry({required this.assignment, required this.period});

  final TeachingAssignmentEntity assignment;
  final TeachingPeriodEntity? period;

  int get subjectId => assignment.subjectId;
  String get subjectName => assignment.subjectName;
}

/// One course (grado + grupo) and the subjects the teacher teaches in it.
class CourseClasses {
  const CourseClasses({
    required this.groupId,
    required this.gradeName,
    required this.groupName,
    required this.academicYear,
    required this.label,
    required this.entries,
  });

  final int groupId;
  final String gradeName;
  final String groupName;
  final int academicYear;

  /// "6° A", with the year only when another course reads the same.
  final String label;

  /// By subject name.
  final List<ClassEntry> entries;

  /// Active students of the group, from any of its classes; null when no
  /// class exists yet in the chosen period.
  int? get studentCount =>
      entries.map((e) => e.period?.studentCount).nonNulls.firstOrNull;
}

/// The courses of one grade, in natural group order.
class GradeSection {
  const GradeSection({required this.gradeName, required this.courses});

  final String gradeName;
  final List<CourseClasses> courses;
}

/// The teacher's classes as the UI shows them: grade → course → subject.
class ClassGrouping {
  const ClassGrouping(this.sections);

  final List<GradeSection> sections;

  Iterable<CourseClasses> get courses => sections.expand((s) => s.courses);
  Iterable<ClassEntry> get entries => courses.expand((c) => c.entries);

  int get courseCount => courses.length;

  /// Subjects that have a class in the chosen period.
  int get classCount => entries.where((e) => e.period != null).length;

  Set<int> get subjectIds => {for (final e in entries) e.subjectId};

  /// Every shown class is of the same subject: name it once (in the
  /// header) instead of in every row.
  String? get singleSubjectName =>
      subjectIds.length == 1 ? entries.first.subjectName : null;

  bool get isEmpty => sections.isEmpty;
}

/// Groups [assignments] by grade and course, pairing each with its class
/// in [academicPeriodId] (null: its most recent class). [include] filters
/// entries (subject, status, search) before grouping, so courses left
/// without entries disappear.
ClassGrouping groupClasses({
  required List<TeachingAssignmentEntity> assignments,
  required List<TeachingPeriodEntity> periods,
  int? academicPeriodId,
  bool Function(ClassEntry entry, String courseLabel)? include,
}) {
  final labels = courseLabels([
    for (final a in assignments)
      (
        groupId: a.groupId,
        gradeName: a.gradeName,
        groupName: a.groupName,
        academicYear: a.academicYear,
      ),
  ]);

  final byGroup = <int, List<ClassEntry>>{};
  final firstOfGroup = <int, TeachingAssignmentEntity>{};
  for (final a in assignments) {
    final entry = ClassEntry(
      assignment: a,
      period: classForAssignment(
        a,
        periods,
        academicPeriodId: academicPeriodId,
      ),
    );
    if (include != null && !include(entry, labels[a.groupId]!)) continue;
    (byGroup[a.groupId] ??= []).add(entry);
    firstOfGroup.putIfAbsent(a.groupId, () => a);
  }

  final courses = [
    for (final MapEntry(key: groupId, value: entries) in byGroup.entries)
      CourseClasses(
        groupId: groupId,
        gradeName: firstOfGroup[groupId]!.gradeName,
        groupName: firstOfGroup[groupId]!.groupName,
        academicYear: firstOfGroup[groupId]!.academicYear,
        label: labels[groupId]!,
        entries: entries
          ..sort(
            (a, b) => a.subjectName.toLowerCase().compareTo(
              b.subjectName.toLowerCase(),
            ),
          ),
      ),
  ]..sort(_courseOrder);

  final sections = <GradeSection>[];
  for (final course in courses) {
    final last = sections.lastOrNull;
    if (last != null && last.gradeName == course.gradeName) {
      last.courses.add(course);
    } else {
      sections.add(
        GradeSection(gradeName: course.gradeName, courses: [course]),
      );
    }
  }
  return ClassGrouping(sections);
}

/// Grade (natural), then group name, then newest year first.
int _courseOrder(CourseClasses a, CourseClasses b) {
  final byGrade = compareGradeNames(a.gradeName, b.gradeName);
  if (byGrade != 0) return byGrade;
  final byGroup = a.groupName.toLowerCase().compareTo(
    b.groupName.toLowerCase(),
  );
  if (byGroup != 0) return byGroup;
  return b.academicYear.compareTo(a.academicYear);
}

/// One course and its classes (of one or several academic periods).
class CoursePeriods {
  const CoursePeriods({required this.label, required this.classes});

  /// "6° A", with the year only when another course reads the same.
  final String label;

  /// By subject, then newest period first.
  final List<TeachingPeriodEntity> classes;
}

/// [periods] grouped by course, courses in natural grade order — what the
/// class picker lists.
List<CoursePeriods> groupPeriodsByCourse(List<TeachingPeriodEntity> periods) {
  final labels = courseLabels([
    for (final p in periods)
      (
        groupId: p.groupId,
        gradeName: p.gradeName,
        groupName: p.groupName,
        academicYear: p.academicYear,
      ),
  ]);
  final byGroup = <int, List<TeachingPeriodEntity>>{};
  for (final p in periods) {
    (byGroup[p.groupId] ??= []).add(p);
  }
  final groups = byGroup.values.toList()
    ..sort((a, b) {
      final x = a.first;
      final y = b.first;
      final byGrade = compareGradeNames(x.gradeName, y.gradeName);
      if (byGrade != 0) return byGrade;
      final byGroup = x.groupName.toLowerCase().compareTo(
        y.groupName.toLowerCase(),
      );
      return byGroup != 0 ? byGroup : y.academicYear.compareTo(x.academicYear);
    });
  return [
    for (final classes in groups)
      CoursePeriods(
        label: labels[classes.first.groupId]!,
        classes: classes
          ..sort((a, b) {
            final bySubject = a.subjectName.toLowerCase().compareTo(
              b.subjectName.toLowerCase(),
            );
            return bySubject != 0
                ? bySubject
                : b.startDate.compareTo(a.startDate);
          }),
      ),
  ];
}
