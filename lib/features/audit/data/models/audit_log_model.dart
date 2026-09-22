import '../../../../core/utils/formatters.dart';
import '../../domain/entities/audit_log_entity.dart';

class AuditLogModel {
  static AuditLogEntity fromJson(Map<String, dynamic> json) => AuditLogEntity(
    id: json['id'] as int,
    action: auditActionFromJson(json['action'] as String),
    entityType: json['entityType'] as String? ?? '',
    entityId: json['entityId'] as int?,
    result: json['result'] as String,
    details: json['details'] as String?,
    createdAt: Formatters.parseApiDateTime(json['createdAt'] as String),
  );
}
