import '../../../../core/cache/paging.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/student_entity.dart';
import '../datasources/student_remote_datasource.dart';

class StudentRepository {
  StudentRepository(this._remote);

  final StudentRemoteDataSource _remote;

  Future<ApiPage<StudentEntity>> getPage({
    int page = 0,
    int size = 20,
    int? groupId,
    String? search,
  }) =>
      _remote.getPage(page: page, size: size, groupId: groupId, search: search);

  /// Every student of one group (all pages).
  Future<List<StudentEntity>> getGroup(int groupId) => fetchAllPages(
    (page, size) => _remote.getPage(page: page, size: size, groupId: groupId),
  );

  Future<StudentDetailEntity> getById(int id) => _remote.getById(id);

  Future<void> withdraw(int studentId, int groupId) =>
      _remote.withdraw(studentId, groupId);

  /// Permanent: removes the student and all of their data.
  Future<void> delete(int id) => _remote.delete(id);
}
