import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/audit_log_entity.dart';

/// API filter value for each [AuditAction].
const auditActionApiValues = <AuditAction, String>{
  AuditAction.login: 'LOGIN',
  AuditAction.logout: 'LOGOUT',
  AuditAction.create: 'CREATE',
  AuditAction.update: 'UPDATE',
  AuditAction.delete: 'DELETE',
  AuditAction.import: 'IMPORT',
  AuditAction.export: 'EXPORT',
  AuditAction.examProcessed: 'EXAM_PROCESSED',
  AuditAction.gradeUpdated: 'GRADE_UPDATED',
  AuditAction.answerUpdated: 'ANSWER_UPDATED',
};

String auditActionLabel(AuditAction action) => switch (action) {
  AuditAction.login => 'Inicio de sesión',
  AuditAction.logout => 'Cierre de sesión',
  AuditAction.create => 'Creación',
  AuditAction.update => 'Actualización',
  AuditAction.delete => 'Eliminación',
  AuditAction.import => 'Importación',
  AuditAction.export => 'Exportación',
  AuditAction.examProcessed => 'Examen procesado',
  AuditAction.gradeUpdated => 'Calificación actualizada',
  AuditAction.answerUpdated => 'Respuesta corregida',
};

/// The backend's readable label ("Parcial 1 · Ana Pérez") when it has
/// one; older or non-class entries fall back to "Tipo #id".
String auditEntityLabel(AuditLogEntity log) =>
    log.entityLabel ??
    '${log.entityType}${log.entityId != null ? ' #${log.entityId}' : ''}';

IconData auditResultIcon(AuditLogEntity log) =>
    log.isSuccess ? Icons.check_circle_outline : Icons.error_outline;

Color auditResultColor(AuditLogEntity log) =>
    log.isSuccess ? AppColors.success : AppColors.error;

IconData auditActionIcon(AuditAction action) => switch (action) {
  AuditAction.login => Icons.login,
  AuditAction.logout => Icons.logout,
  AuditAction.create => Icons.add_circle_outline,
  AuditAction.update => Icons.edit_outlined,
  AuditAction.delete => Icons.delete_outline,
  AuditAction.import => Icons.upload_file_outlined,
  AuditAction.export => Icons.download_outlined,
  AuditAction.examProcessed => Icons.fact_check_outlined,
  AuditAction.gradeUpdated => Icons.grade_outlined,
  AuditAction.answerUpdated => Icons.rule_outlined,
};

/// Accent for a successful audit action in the activity feeds (failures
/// use the error color instead).
Color auditActionAccent(AuditAction action) => switch (action) {
  AuditAction.create ||
  AuditAction.examProcessed ||
  AuditAction.gradeUpdated => AppColors.accentGreen,
  AuditAction.import || AuditAction.export => AppColors.accentTeal,
  AuditAction.update || AuditAction.answerUpdated => AppColors.accentPurple,
  AuditAction.delete => AppColors.accentOrange,
  AuditAction.login || AuditAction.logout => AppColors.accentBlue,
};
