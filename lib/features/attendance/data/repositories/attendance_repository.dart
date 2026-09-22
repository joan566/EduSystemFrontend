import '../../../../core/state/list_state.dart';
import '../../domain/entities/attendance_entity.dart';
import '../datasources/attendance_remote_datasource.dart';

class AttendanceRepository {
  AttendanceRepository(this._remote);

  final AttendanceRemoteDataSource _remote;

  Future<AttendanceSessionEntity> create({
    required int teachingPeriodId,
    required DateTime sessionDate,
    String? name,
    double? maximumScore,
  }) => _remote.create(
    teachingPeriodId: teachingPeriodId,
    sessionDate: sessionDate,
    name: name,
    maximumScore: maximumScore,
  );

  Future<ApiPage<AttendanceSessionEntity>> getPage({required int teachingPeriodId, int page = 0}) =>
      _remote.getPage(teachingPeriodId: teachingPeriodId, page: page);

  Future<SessionDetailEntity> getById(int id) => _remote.getById(id);

  Future<SessionDetailEntity> putRecords(
    int id,
    List<({int studentId, AttendanceStatus status, String? observation})> records,
  ) => _remote.putRecords(id, records);

  Future<void> delete(int id) => _remote.delete(id);
}
