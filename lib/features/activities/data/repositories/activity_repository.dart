import '../../../../core/state/list_state.dart';
import '../../domain/entities/activity_entity.dart';
import '../datasources/activity_remote_datasource.dart';

class ActivityRepository {
  ActivityRepository(this._remote);

  final ActivityRemoteDataSource _remote;

  Future<ActivityEntity> create({
    required int teachingPeriodId,
    required String name,
    String? description,
    DateTime? evaluationDate,
    required double maximumScore,
    String? activityType,
  }) => _remote.create(
    teachingPeriodId: teachingPeriodId,
    name: name,
    description: description,
    evaluationDate: evaluationDate,
    maximumScore: maximumScore,
    activityType: activityType,
  );

  Future<ApiPage<ActivityEntity>> getPage({required int teachingPeriodId, int page = 0}) =>
      _remote.getPage(teachingPeriodId: teachingPeriodId, page: page);

  Future<ActivityEntity> getById(int id) => _remote.getById(id);

  Future<ActivityEntity> update(
    int id, {
    required String name,
    String? description,
    DateTime? evaluationDate,
    double? maximumScore,
    String? activityType,
  }) => _remote.update(
    id,
    name: name,
    description: description,
    evaluationDate: evaluationDate,
    maximumScore: maximumScore,
    activityType: activityType,
  );

  Future<void> delete(int id) => _remote.delete(id);

  Future<List<StudentGradeEntity>> getGrades(int id) => _remote.getGrades(id);

  Future<List<StudentGradeEntity>> putGrades(
    int id,
    List<({int studentId, double grade, String? comment})> grades,
  ) => _remote.putGrades(id, grades);

  Future<List<StudentGradeEntity>> putStudentGrade(
    int id,
    int studentId, {
    required double grade,
    String? comment,
  }) => _remote.putStudentGrade(id, studentId, grade: grade, comment: comment);
}
