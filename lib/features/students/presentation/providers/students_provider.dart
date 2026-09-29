import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/entities/student_entity.dart';

class StudentsProvider extends ChangeNotifier {
  StudentsProvider(this._repository);

  final StudentRepository _repository;
  int? _groupFilter;
  String? _search;

  ListViewState<StudentEntity> _state = const ListViewState();
  ListViewState<StudentEntity> get state => _state;

  DetailViewState<StudentDetailEntity> _detailState = const DetailViewState();
  DetailViewState<StudentDetailEntity> get detailState => _detailState;

  Future<void> load({int page = 0, int? groupId, String? search, bool resetFilters = false}) async {
    if (resetFilters) {
      _groupFilter = null;
    } else {
      _groupFilter = groupId ?? _groupFilter;
    }
    _search = search ?? _search;
    _state = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _repository.getPage(page: page, groupId: _groupFilter, search: _search);
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

  final Map<int, ListViewState<StudentEntity>> _groupRosters = {};

  /// Students of one group (e.g. a class's roster). Kept apart from
  /// [state] so it never changes the Students screen's own filters.
  ListViewState<StudentEntity> groupRoster(int groupId) =>
      _groupRosters[groupId] ?? const ListViewState();

  Future<void> loadGroupRoster(int groupId) async {
    _groupRosters[groupId] = ListViewState.loading();
    notifyListeners();
    try {
      // A whole class at once (the API's max page), so rosters and
      // per-student lists aren't cut at the default 20.
      final result = await _repository.getPage(page: 0, size: 100, groupId: groupId);
      _groupRosters[groupId] = ListViewState.fromPage(
        content: result.content,
        page: result.page,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
      );
    } on AppException catch (e) {
      _groupRosters[groupId] = ListViewState.error(e);
    }
    notifyListeners();
  }

  Future<void> search(String query) => load(page: 0, search: query.isEmpty ? null : query);

  Future<void> loadDetail(int id) async {
    _detailState = DetailViewState.loading();
    notifyListeners();
    try {
      final detail = await _repository.getById(id);
      _detailState = DetailViewState.success(detail);
    } on AppException catch (e) {
      _detailState = DetailViewState.error(e);
    }
    notifyListeners();
  }

  Future<AppException?> withdraw(int studentId, int groupId) async {
    try {
      await _repository.withdraw(studentId, groupId);
      await loadDetail(studentId);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
