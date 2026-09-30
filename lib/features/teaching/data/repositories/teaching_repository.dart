import '../../../../core/cache/paging.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../../domain/entities/teaching_period_summary_entity.dart';
import '../datasources/teaching_remote_datasource.dart';

class TeachingRepository {
  TeachingRepository(this._remote);

  final TeachingRemoteDataSource _remote;

  Future<ApiPage<TeachingAssignmentEntity>> getAssignments({
    int page = 0,
    int? groupId,
    int? subjectId,
    bool? active,
  }) => _remote.getAssignments(
    page: page,
    groupId: groupId,
    subjectId: subjectId,
    active: active,
  );

  /// Every assignment of the teacher (all pages).
  Future<List<TeachingAssignmentEntity>> getAllAssignments() => fetchAllPages(
    (page, size) => _remote.getAssignments(page: page, size: size),
  );

  Future<TeachingAssignmentEntity> createAssignment({
    required int groupId,
    required int subjectId,
  }) => _remote.createAssignment(groupId: groupId, subjectId: subjectId);

  Future<void> setAssignmentActive(int id, bool active) =>
      _remote.setAssignmentActive(id, active);

  Future<void> deleteAssignment(int id) => _remote.deleteAssignment(id);

  Future<ApiPage<TeachingPeriodEntity>> getPeriods({
    int page = 0,
    int? teachingAssignmentId,
    int? academicPeriodId,
  }) => _remote.getPeriods(
    page: page,
    teachingAssignmentId: teachingAssignmentId,
    academicPeriodId: academicPeriodId,
  );

  /// Every class of the teacher (all pages).
  Future<List<TeachingPeriodEntity>> getAllPeriods() =>
      fetchAllPages((page, size) => _remote.getPeriods(page: page, size: size));

  Future<TeachingPeriodEntity> createPeriod({
    required int teachingAssignmentId,
    required int academicPeriodId,
  }) => _remote.createPeriod(
    teachingAssignmentId: teachingAssignmentId,
    academicPeriodId: academicPeriodId,
  );

  Future<TeachingPeriodEntity> getPeriod(int id) => _remote.getPeriod(id);

  Future<TeachingPeriodSummaryEntity> getPeriodSummary(int id) =>
      _remote.getPeriodSummary(id);

  Future<void> deletePeriod(int id) => _remote.deletePeriod(id);
}
