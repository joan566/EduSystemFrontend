import '../../../../core/cache/paging.dart';
import '../../domain/entities/academic_period_entity.dart';
import '../datasources/academic_period_remote_datasource.dart';

class AcademicPeriodRepository {
  AcademicPeriodRepository(this._remote);

  final AcademicPeriodRemoteDataSource _remote;

  /// Every academic period of the teacher (all pages).
  Future<List<AcademicPeriodEntity>> getAll() =>
      fetchAllPages((page, size) => _remote.getPage(page: page, size: size));

  Future<AcademicPeriodEntity> create({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) => _remote.create(name: name, startDate: startDate, endDate: endDate);

  Future<AcademicPeriodEntity> update(
    int id, {
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) => _remote.update(id, name: name, startDate: startDate, endDate: endDate);

  Future<void> delete(int id) => _remote.delete(id);
}
