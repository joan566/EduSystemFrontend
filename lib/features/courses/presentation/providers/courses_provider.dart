import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/course_repository.dart';
import '../../domain/entities/course_entity.dart';

class CoursesProvider extends ChangeNotifier {
  CoursesProvider(this._repository);

  final CourseRepository _repository;
  int? _gradeFilter;
  int? _yearFilter;

  ListViewState<CourseEntity> _state = const ListViewState();
  ListViewState<CourseEntity> get state => _state;
  int? get gradeFilter => _gradeFilter;
  int? get yearFilter => _yearFilter;

  /// Sets the level and year filters exactly (null clears each) and loads
  /// the first page.
  Future<void> applyFilters({int? gradeId, int? academicYear}) {
    _gradeFilter = gradeId;
    _yearFilter = academicYear;
    return load();
  }

  Future<void> load({int page = 0, int? gradeId, int? academicYear, bool resetFilters = false}) async {
    if (resetFilters) {
      _gradeFilter = null;
      _yearFilter = null;
    } else {
      _gradeFilter = gradeId ?? _gradeFilter;
      _yearFilter = academicYear ?? _yearFilter;
    }
    _state = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _repository.getPage(
        page: page,
        gradeId: _gradeFilter,
        academicYear: _yearFilter,
      );
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
    required int gradeId,
    required String name,
    required int academicYear,
  }) async {
    try {
      await _repository.create(gradeId: gradeId, name: name, academicYear: academicYear);
      await load(page: 0);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> update(int id, {required String name, required int academicYear}) async {
    try {
      await _repository.update(id, name: name, academicYear: academicYear);
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
