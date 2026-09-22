import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../models/audit_log_model.dart';

class AuditRemoteDataSource {
  AuditRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ApiPage<AuditLogEntity>> getPage({
    int page = 0,
    int size = 20,
    String? action,
    String? entityType,
    int? entityId,
  }) async {
    final response = await _client.get(
      ApiEndpoints.auditLogs,
      queryParameters: {
        'page': page,
        'size': size,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
      },
    );
    return ApiPage.fromJson(response.data as Map<String, dynamic>, AuditLogModel.fromJson);
  }
}
