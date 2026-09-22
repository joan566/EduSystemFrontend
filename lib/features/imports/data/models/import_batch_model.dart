import '../../../../core/utils/formatters.dart';
import '../../domain/entities/import_batch_entity.dart';

class ImportBatchModel {
  static ImportBatchEntity fromJson(Map<String, dynamic> json) =>
      ImportBatchEntity(
        id: json['id'] as int,
        fileName: json['fileName'] as String,
        status: importStatusFromJson(json['status'] as String),
        totalRows: json['totalRows'] as int,
        successfulRows: json['successfulRows'] as int,
        failedRows: json['failedRows'] as int,
        hasErrorReport: json['hasErrorReport'] as bool? ?? false,
        createdAt: Formatters.parseApiDateTime(json['createdAt'] as String),
        completedAt: json['completedAt'] == null
            ? null
            : Formatters.parseApiDateTime(json['completedAt'] as String),
      );

  /// Parses the immediate `POST /imports/students` response. Unlike the
  /// history listing, that endpoint's envelope (`ImportResultResponse` on
  /// the backend) does NOT echo `fileName`, `hasErrorReport`, `createdAt`
  /// or `completedAt` — so this can't just delegate to [fromJson]. Missing
  /// fields fall back to values already known client-side (the file the
  /// user just picked) or a reasonable default.
  static ImportResultEntity resultFromJson(
    Map<String, dynamic> json, {
    required String fallbackFileName,
  }) {
    final failedRows = json['failedRows'] as int? ?? 0;
    final batch = ImportBatchEntity(
      id: json['id'] as int,
      fileName: json['fileName'] as String? ?? fallbackFileName,
      status: importStatusFromJson(json['status'] as String),
      totalRows: json['totalRows'] as int,
      successfulRows: json['successfulRows'] as int,
      failedRows: failedRows,
      hasErrorReport: json['hasErrorReport'] as bool? ?? failedRows > 0,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : Formatters.parseApiDateTime(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : Formatters.parseApiDateTime(json['completedAt'] as String),
    );
    return ImportResultEntity(
      batch: batch,
      errors: (json['errors'] as List<dynamic>? ?? const [])
          .map(
            (e) => ImportRowError(
              row: (e as Map<String, dynamic>)['row'] as int,
              column: e['column'] as String? ?? '',
              message: e['message'] as String? ?? '',
            ),
          )
          .toList(),
      errorsTruncated: json['errorsTruncated'] as bool? ?? false,
    );
  }
}
