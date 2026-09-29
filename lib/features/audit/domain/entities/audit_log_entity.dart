enum AuditAction {
  login,
  logout,
  create,
  update,
  delete,
  import,
  export,
  examProcessed,
  gradeUpdated,
  answerUpdated,
}

AuditAction auditActionFromJson(String value) => switch (value) {
  'LOGIN' => AuditAction.login,
  'LOGOUT' => AuditAction.logout,
  'CREATE' => AuditAction.create,
  'UPDATE' => AuditAction.update,
  'DELETE' => AuditAction.delete,
  'IMPORT' => AuditAction.import,
  'EXPORT' => AuditAction.export,
  'EXAM_PROCESSED' => AuditAction.examProcessed,
  'GRADE_UPDATED' => AuditAction.gradeUpdated,
  'ANSWER_UPDATED' => AuditAction.answerUpdated,
  _ => AuditAction.update,
};

class AuditLogEntity {
  const AuditLogEntity({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.teachingPeriodId,
    this.entityLabel,
    required this.result,
    required this.details,
    required this.createdAt,
  });

  final int id;
  final AuditAction action;
  final String entityType;
  final int? entityId;

  /// Class (teaching period) the action belongs to, when it belongs to one.
  final int? teachingPeriodId;

  /// Human-readable target, e.g. "Parcial 1 · Ana Pérez".
  final String? entityLabel;
  final String result;
  final String? details;
  final DateTime createdAt;

  bool get isSuccess => result == 'SUCCESS';
}
