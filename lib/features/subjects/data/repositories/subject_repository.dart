import '../../../../core/state/list_state.dart';
import '../../domain/entities/subject_entity.dart';
import '../datasources/subject_remote_datasource.dart';

class SubjectRepository {
  SubjectRepository(this._remote);

  final SubjectRemoteDataSource _remote;

  Future<ApiPage<SubjectEntity>> getPage({int page = 0, String? name}) =>
      _remote.getPage(page: page, name: name);

  Future<SubjectEntity> create({required String name, String? description}) =>
      _remote.create(name: name, description: description);

  Future<SubjectEntity> update(int id, {required String name, String? description}) =>
      _remote.update(id, name: name, description: description);

  Future<void> delete(int id) => _remote.delete(id);
}
