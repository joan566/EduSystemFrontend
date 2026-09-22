import '../../../../core/state/list_state.dart';
import '../../domain/entities/course_entity.dart';
import '../datasources/course_remote_datasource.dart';

class CourseRepository {
  CourseRepository(this._remote);

  final CourseRemoteDataSource _remote;

  Future<ApiPage<CourseEntity>> getPage({int page = 0, int? gradeId, int? academicYear}) =>
      _remote.getPage(page: page, gradeId: gradeId, academicYear: academicYear);

  Future<CourseEntity> create({
    required int gradeId,
    required String name,
    required int academicYear,
  }) => _remote.create(gradeId: gradeId, name: name, academicYear: academicYear);

  Future<CourseEntity> update(int id, {required String name, required int academicYear}) =>
      _remote.update(id, name: name, academicYear: academicYear);

  Future<void> delete(int id) => _remote.delete(id);
}
