import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/subject_repository.dart';
import '../../domain/entities/subject_entity.dart';

class SubjectsProvider extends ChangeNotifier {
  SubjectsProvider(this._repository);

  final SubjectRepository _repository;
  String? _search;

  ListViewState<SubjectEntity> _state = const ListViewState();
  ListViewState<SubjectEntity> get state => _state;

  Future<void> load({int page = 0, String? search}) async {
    _search = search ?? _search;
    _state = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _repository.getPage(page: page, name: _search);
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

  Future<void> search(String query) => load(page: 0, search: query.isEmpty ? null : query);

  Future<AppException?> create({required String name, String? description}) async {
    try {
      await _repository.create(name: name, description: description);
      await load(page: 0);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> update(int id, {required String name, String? description}) async {
    try {
      await _repository.update(id, name: name, description: description);
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
