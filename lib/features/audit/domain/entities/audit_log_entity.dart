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
    required this.result,
    required this.details,
    required this.createdAt,
  });

  final int id;
  final AuditAction action;
  final String entityType;
  final int? entityId;
  final String result;
  final String? details;
  final DateTime createdAt;

  bool get isSuccess => result == 'SUCCESS';
}
