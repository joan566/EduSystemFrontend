import '../../domain/entities/academic_level_entity.dart';
import '../datasources/academic_level_remote_datasource.dart';

/// Thin pass-through repository. No abstract interface: there is a single
/// implementation and no domain logic beyond the HTTP call, so an
/// interface here would be indirection without payoff (§92).
class AcademicLevelRepository {
  AcademicLevelRepository(this._remote);

  final AcademicLevelRemoteDataSource _remote;

  Future<List<AcademicLevelEntity>> getAll() => _remote.getAll();

  Future<AcademicLevelEntity> create({required String name, String? description}) =>
      _remote.create(name: name, description: description);

  Future<AcademicLevelEntity> update(int id, {required String name, String? description}) =>
      _remote.update(id, name: name, description: description);

  Future<void> delete(int id) => _remote.delete(id);
}
