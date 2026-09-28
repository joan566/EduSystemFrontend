import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../audit/domain/entities/audit_log_entity.dart';

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
