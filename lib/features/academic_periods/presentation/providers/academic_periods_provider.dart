import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/academic_period_repository.dart';
import '../../domain/entities/academic_period_entity.dart';

class AcademicPeriodsProvider extends ChangeNotifier {
  AcademicPeriodsProvider(this._repository);

  final AcademicPeriodRepository _repository;

  ListViewState<AcademicPeriodEntity> _state = const ListViewState();
  ListViewState<AcademicPeriodEntity> get state => _state;

  Future<void> load({int page = 0}) async {
    _state = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _repository.getPage(page: page);
      _state = ListViewState.fromPage(
        content: result.content,
        page: result.page,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
      );
    } on AppException catch (e) {
      _state = ListViewState.error(e);
    }
    notifyListeners();
  }

  Future<AppException?> create({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      await _repository.create(name: name, startDate: startDate, endDate: endDate);
      await load(page: 0);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> update(
    int id, {
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      await _repository.update(id, name: name, startDate: startDate, endDate: endDate);
      await load(page: _state.page);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> delete(int id) async {
    try {
      await _repository.delete(id);
      await load(page: _state.page);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
