import '../../../../core/utils/formatters.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';

class TeachingAssignmentModel {
  static TeachingAssignmentEntity fromJson(Map<String, dynamic> json) =>
      TeachingAssignmentEntity(
        id: json['id'] as int,
        groupId: json['groupId'] as int,
        groupName: json['groupName'] as String,
        gradeName: json['gradeName'] as String,
        academicYear: json['academicYear'] as int,
        subjectId: json['subjectId'] as int,
        subjectName: json['subjectName'] as String,
        active: json['active'] as bool,
      );
}

class TeachingPeriodModel {
  static TeachingPeriodEntity fromJson(Map<String, dynamic> json) => TeachingPeriodEntity(
    id: json['id'] as int,
    teachingAssignmentId: json['teachingAssignmentId'] as int,
    groupId: json['groupId'] as int,
    groupName: json['groupName'] as String,
    gradeName: json['gradeName'] as String,
    academicYear: json['academicYear'] as int,
    subjectId: json['subjectId'] as int,
    subjectName: json['subjectName'] as String,
    academicPeriodId: json['academicPeriodId'] as int,
    academicPeriodName: json['academicPeriodName'] as String,
    startDate: Formatters.parseApiDate(json['startDate'] as String),
    endDate: Formatters.parseApiDate(json['endDate'] as String),
  );
}
