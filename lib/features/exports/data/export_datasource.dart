import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class ExportDataSource {
  ExportDataSource(this._client);

  final ApiClient _client;

  Future<BinaryDownload> exportStudents({
    int? teachingPeriodId,
    int? groupId,
  }) => _client.getBinary(
    ApiEndpoints.exportStudents,
    queryParameters: {'teachingPeriodId': teachingPeriodId, 'groupId': groupId},
  );

  Future<BinaryDownload> exportGrades({required int teachingPeriodId}) =>
      _client.getBinary(
        ApiEndpoints.exportGrades,
        queryParameters: {'teachingPeriodId': teachingPeriodId},
      );

  Future<BinaryDownload> exportAttendance({required int teachingPeriodId}) =>
      _client.getBinary(
        ApiEndpoints.exportAttendance,
        queryParameters: {'teachingPeriodId': teachingPeriodId},
      );

  /// Combined Students + Grades + Attendance workbook for a teaching
  /// period. This same file is the template for re-importing via
  /// [ApiEndpoints.importTeachingPeriod] — the activity/session column
  /// headers it carries (e.g. `Taller 1 #12 (max 5)`) must be preserved
  /// as-is if the app ever edits the file programmatically.
  Future<BinaryDownload> exportTeachingPeriodFull({
    required int teachingPeriodId,
  }) => _client.getBinary(
    ApiEndpoints.exportTeachingPeriodFull(teachingPeriodId),
  );
}
