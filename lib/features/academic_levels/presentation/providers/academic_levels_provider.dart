import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/academic_level_repository.dart';
import '../../domain/entities/academic_level_entity.dart';

class AcademicLevelsProvider extends ChangeNotifier {
  AcademicLevelsProvider(this._repository);

  final AcademicLevelRepository _repository;

  ListViewState<AcademicLevelEntity> _state = const ListViewState();
  ListViewState<AcademicLevelEntity> get state => _state;

  Future<void> load() async {
    _state = ListViewState.loading();
    notifyListeners();
    try {
      final items = await _repository.getAll();
      _state = ListViewState.list(items);
    } on AppException catch (e) {
      _state = ListViewState.error(e);
    }
    notifyListeners();
  }

  Future<AppException?> create({required String name, String? description}) async {
    try {
      await _repository.create(name: name, description: description);
      await load();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> update(int id, {required String name, String? description}) async {
    try {
      await _repository.update(id, name: name, description: description);
      await load();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> delete(int id) async {
    try {
      await _repository.delete(id);
      await load();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
