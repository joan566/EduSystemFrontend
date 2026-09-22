enum ImportStatus { processing, completed, completedWithErrors, failed }

ImportStatus importStatusFromJson(String value) => switch (value) {
  'PROCESSING' => ImportStatus.processing,
  'COMPLETED' => ImportStatus.completed,
  'COMPLETED_WITH_ERRORS' => ImportStatus.completedWithErrors,
  'FAILED' => ImportStatus.failed,
  _ => ImportStatus.failed,
};

class ImportBatchEntity {
  const ImportBatchEntity({
    required this.id,
    required this.fileName,
    required this.status,
    required this.totalRows,
    required this.successfulRows,
    required this.failedRows,
    required this.hasErrorReport,
    required this.createdAt,
    this.completedAt,
  });

  final int id;
  final String fileName;
  final ImportStatus status;
  final int totalRows;
  final int successfulRows;
  final int failedRows;
  final bool hasErrorReport;
  final DateTime createdAt;
  final DateTime? completedAt;
}

class ImportRowError {
  const ImportRowError({
    required this.row,
    required this.column,
    required this.message,
  });

  final int row;
  final String column;
  final String message;
}

/// The immediate response to `POST /imports/students` — includes the row
/// errors the plain [ImportBatchEntity] (history listing) does not.
class ImportResultEntity {
  const ImportResultEntity({
    required this.batch,
    required this.errors,
    required this.errorsTruncated,
  });

  final ImportBatchEntity batch;
  final List<ImportRowError> errors;
  final bool errorsTruncated;
}
