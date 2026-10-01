import '../../../../core/utils/course_naming.dart';

class StudentEntity {
  const StudentEntity({
    required this.id,
    required this.studentCode,
    required this.identificationNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.currentEnrollment,
  });

  final int id;
  final String studentCode;
  final String identificationNumber;
  final String firstName;
  final String lastName;
  final String email;

  /// Current course (listing only): the filtered group's enrollment, else
  /// the latest active one; null if never enrolled or not a listing.
  final StudentEnrollmentEntity? currentEnrollment;

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}'
              '${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();
}

class StudentEnrollmentEntity {
  const StudentEnrollmentEntity({
    required this.groupId,
    required this.groupName,
    required this.gradeName,
    required this.academicYear,
    required this.enrolledAt,
    this.withdrawnAt,
    required this.active,
  });

  final int groupId;
  final String groupName;
  final String gradeName;
  final int academicYear;
  final DateTime enrolledAt;
  final DateTime? withdrawnAt;
  final bool active;

  String get courseLabel => courseName(gradeName, groupName);
}

class StudentDetailEntity {
  const StudentDetailEntity({required this.student, required this.enrollments});

  final StudentEntity student;
  final List<StudentEnrollmentEntity> enrollments;
}
