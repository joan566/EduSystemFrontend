import '../../../../core/utils/formatters.dart';
import '../../domain/entities/attendance_entity.dart';

class AttendanceSessionModel {
  static AttendanceSessionEntity fromJson(Map<String, dynamic> json) => AttendanceSessionEntity(
    id: json['id'] as int,
    evaluationId: json['evaluationId'] as int,
    teachingPeriodId: json['teachingPeriodId'] as int,
    name: json['name'] as String?,
    sessionDate: Formatters.parseApiDate(json['sessionDate'] as String),
    maximumScore: (json['maximumScore'] as num).toDouble(),
  );
}

class SessionStudentRecordModel {
  static SessionStudentRecord fromJson(Map<String, dynamic> json) => SessionStudentRecord(
    studentId: json['studentId'] as int,
    studentCode: json['studentCode'] as String,
    studentName: json['studentName'] as String,
    status: attendanceStatusFromJson(json['status'] as String?),
    observation: json['observation'] as String?,
  );
}

class SessionDetailModel {
  static SessionDetailEntity fromJson(Map<String, dynamic> json) => SessionDetailEntity(
    session: AttendanceSessionModel.fromJson(json['session'] as Map<String, dynamic>),
    students: (json['students'] as List<dynamic>)
        .map((e) => SessionStudentRecordModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
