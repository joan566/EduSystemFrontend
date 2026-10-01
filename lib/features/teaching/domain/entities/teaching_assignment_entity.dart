import '../../../../core/utils/course_naming.dart';

/// A teacher's assignment to teach a [subjectName] in a [groupName]
/// (§4: group + subject, scoped to the authenticated teacher).
class TeachingAssignmentEntity {
  const TeachingAssignmentEntity({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.gradeName,
    required this.academicYear,
    required this.subjectId,
    required this.subjectName,
    required this.active,
  });

  final int id;
  final int groupId;
  final String groupName;
  final String gradeName;
  final int academicYear;
  final int subjectId;
  final String subjectName;
  final bool active;

  /// "6° A".
  String get courseLabel => courseName(gradeName, groupName);

  /// "Matemáticas · 6° A".
  String get title => '$subjectName · $courseLabel';

  TeachingAssignmentEntity copyWith({bool? active}) => TeachingAssignmentEntity(
    id: id,
    groupId: groupId,
    groupName: groupName,
    gradeName: gradeName,
    academicYear: academicYear,
    subjectId: subjectId,
    subjectName: subjectName,
    active: active ?? this.active,
  );
}
