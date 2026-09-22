import '../../../../core/state/list_state.dart';
import '../../domain/entities/academic_period_entity.dart';
import '../datasources/academic_period_remote_datasource.dart';

class AcademicPeriodRepository {
  AcademicPeriodRepository(this._remote);

  final AcademicPeriodRemoteDataSource _remote;

  Future<ApiPage<AcademicPeriodEntity>> getPage({int page = 0}) => _remote.getPage(page: page);

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
