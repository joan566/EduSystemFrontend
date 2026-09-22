enum AttendanceStatus { present, absent, excused }

AttendanceStatus? attendanceStatusFromJson(String? value) => switch (value) {
  'PRESENT' => AttendanceStatus.present,
  'ABSENT' => AttendanceStatus.absent,
  'EXCUSED' => AttendanceStatus.excused,
  _ => null,
};

String attendanceStatusToJson(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => 'PRESENT',
  AttendanceStatus.absent => 'ABSENT',
  AttendanceStatus.excused => 'EXCUSED',
};

class AttendanceSessionEntity {
  const AttendanceSessionEntity({
    required this.id,
    required this.evaluationId,
    required this.teachingPeriodId,
    this.name,
    required this.sessionDate,
    required this.maximumScore,
  });

  final int id;
  final int evaluationId;
  final int teachingPeriodId;
  final String? name;
  final DateTime sessionDate;
  final double maximumScore;
}

class SessionStudentRecord {
  const SessionStudentRecord({
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    this.status,
    this.observation,
  });

  final int studentId;
  final String studentCode;
  final String studentName;
  final AttendanceStatus? status;
  final String? observation;

  SessionStudentRecord copyWith({AttendanceStatus? status, String? observation}) =>
      SessionStudentRecord(
        studentId: studentId,
        studentCode: studentCode,
        studentName: studentName,
        status: status ?? this.status,
        observation: observation ?? this.observation,
      );
}

class SessionDetailEntity {
  const SessionDetailEntity({required this.session, required this.students});

  final AttendanceSessionEntity session;
  final List<SessionStudentRecord> students;
}
