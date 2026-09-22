import '../../../../core/utils/formatters.dart';
import '../../domain/entities/student_entity.dart';

class StudentModel {
  static StudentEntity fromJson(Map<String, dynamic> json) => StudentEntity(
    id: json['id'] as int,
    studentCode: json['studentCode'] as String,
    identificationNumber: json['identificationNumber'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
  );

  static StudentDetailEntity detailFromJson(Map<String, dynamic> json) => StudentDetailEntity(
    student: fromJson(json['student'] as Map<String, dynamic>),
    enrollments: (json['enrollments'] as List<dynamic>)
        .map((e) => _enrollmentFromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static StudentEnrollmentEntity _enrollmentFromJson(Map<String, dynamic> json) =>
      StudentEnrollmentEntity(
        groupId: json['groupId'] as int,
        groupName: json['groupName'] as String,
        gradeName: json['gradeName'] as String,
        academicYear: json['academicYear'] as int,
        enrolledAt: Formatters.parseApiDateTime(json['enrolledAt'] as String),
        withdrawnAt: json['withdrawnAt'] == null
            ? null
            : Formatters.parseApiDateTime(json['withdrawnAt'] as String),
        active: json['active'] as bool,
      );
}
