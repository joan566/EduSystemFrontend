class StudentEntity {
  const StudentEntity({
    required this.id,
    required this.studentCode,
    required this.identificationNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final int id;
  final String studentCode;
  final String identificationNumber;
  final String firstName;
  final String lastName;
  final String email;

  String get fullName => '$firstName $lastName';
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

  String get courseLabel => '$gradeName $groupName';
}

class StudentDetailEntity {
  const StudentDetailEntity({required this.student, required this.enrollments});

  final StudentEntity student;
  final List<StudentEnrollmentEntity> enrollments;
}
