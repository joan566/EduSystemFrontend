/// Imports run in the background: the upload answers `QUEUED` at once and
/// `GET /imports/{id}` moves through `PROCESSING` to one of the finished
/// states.
enum ImportStatus { queued, processing, completed, completedWithErrors, failed }

ImportStatus importStatusFromJson(String value) => switch (value) {
  'QUEUED' => ImportStatus.queued,
  'PROCESSING' => ImportStatus.processing,
  'COMPLETED' => ImportStatus.completed,
  'COMPLETED_WITH_ERRORS' => ImportStatus.completedWithErrors,
  'FAILED' => ImportStatus.failed,
  _ => ImportStatus.failed,
};

/// Which upload produced the import. Null for imports made before the
/// backend recorded it.
enum ImportType { students, teachingPeriod, schoolSetup }

ImportType? importTypeFromJson(String? value) => switch (value) {
  'STUDENTS' => ImportType.students,
  'TEACHING_PERIOD' => ImportType.teachingPeriod,
  'SCHOOL_SETUP' => ImportType.schoolSetup,
  _ => null,
};

class ImportBatchEntity {
  const ImportBatchEntity({
    required this.id,
    required this.fileName,
    required this.status,
    required this.hasErrorReport,
    required this.createdAt,
    this.type,
    this.totalRows,
    this.successfulRows,
    this.failedRows,
    this.errorCode,
    this.errorMessage,
    this.startedAt,
    this.completedAt,
  });

  final int id;
  final ImportType? type;
  final String fileName;
  final ImportStatus status;

  /// Null until the file has been processed.
  final int? totalRows;
  final int? successfulRows;
  final int? failedRows;

  final bool hasErrorReport;

  /// Set when the whole file failed (`MISSING_COLUMNS`, `TOO_MANY_ROWS`,
  /// `INVALID_EXCEL`...): nothing was imported and [errorMessage] says why,
  /// already in Spanish.
  final String? errorCode;
  final String? errorMessage;

  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isActive =>
      status == ImportStatus.queued || status == ImportStatus.processing;

  bool get isFinished => !isActive;

  /// The file itself was rejected, as opposed to a FAILED where every row
  /// had errors (which reads like a partial result).
  bool get failedWholeFile =>
      status == ImportStatus.failed && errorCode != null;
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

/// An import read from `GET /imports/{id}`: the batch plus its first row
/// errors, which the history listing doesn't carry.
class ImportResultEntity {
  const ImportResultEntity({
    required this.batch,
    required this.errors,
    required this.errorsTruncated,
  });

  final ImportBatchEntity batch;

  /// The first row errors (up to 500); [errorsTruncated] says there are
  /// more in the error report.
  final List<ImportRowError> errors;
  final bool errorsTruncated;
}
