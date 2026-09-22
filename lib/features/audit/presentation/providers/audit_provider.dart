import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/list_state.dart';
import '../../data/datasources/audit_remote_datasource.dart';
import '../../domain/entities/audit_log_entity.dart';

class AuditProvider extends ChangeNotifier {
  AuditProvider(this._remote);

  final AuditRemoteDataSource _remote;

  ListViewState<AuditLogEntity> _state = const ListViewState();
  ListViewState<AuditLogEntity> get state => _state;

  Future<void> load({int page = 0, String? action, String? entityType}) async {
    _state = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _remote.getPage(page: page, action: action, entityType: entityType);
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
}
