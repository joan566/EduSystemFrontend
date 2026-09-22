import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/attendance_entity.dart';
import '../models/attendance_models.dart';

class AttendanceRemoteDataSource {
  AttendanceRemoteDataSource(this._client);

  final ApiClient _client;

  Future<AttendanceSessionEntity> create({
    required int teachingPeriodId,
    required DateTime sessionDate,
    String? name,
    double? maximumScore,
  }) async {
    final response = await _client.post(
      ApiEndpoints.attendanceSessions,
      data: {
        'teachingPeriodId': teachingPeriodId,
        'sessionDate': Formatters.toApiDate(sessionDate),
        if (name != null && name.isNotEmpty) 'name': name,
        if (maximumScore != null) 'maximumScore': maximumScore,
      },
    );
    return AttendanceSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiPage<AttendanceSessionEntity>> getPage({
    required int teachingPeriodId,
    int page = 0,
  }) async {
    final response = await _client.get(
      ApiEndpoints.attendanceSessions,
      queryParameters: {'teachingPeriodId': teachingPeriodId, 'page': page, 'size': 20},
    );
    return ApiPage.fromJson(response.data as Map<String, dynamic>, AttendanceSessionModel.fromJson);
  }

  Future<SessionDetailEntity> getById(int id) async {
    final response = await _client.get(ApiEndpoints.attendanceSessionById(id));
    return SessionDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SessionDetailEntity> putRecords(
    int id,
    List<({int studentId, AttendanceStatus status, String? observation})> records,
  ) async {
    final response = await _client.put(
      ApiEndpoints.attendanceRecords(id),
      data: {
        'records': [
          for (final r in records)
            {
              'studentId': r.studentId,
              'status': attendanceStatusToJson(r.status),
              if (r.observation != null && r.observation!.isNotEmpty) 'observation': r.observation,
            },
        ],
      },
    );
    return SessionDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete(ApiEndpoints.attendanceSessionById(id));
}
