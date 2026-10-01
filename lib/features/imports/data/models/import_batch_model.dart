import '../../../../core/utils/formatters.dart';
import '../../domain/entities/import_batch_entity.dart';

class ImportBatchModel {
  /// An import as the upload (202), the history and the detail return it.
  /// The row counts are null while it is queued.
  static ImportBatchEntity fromJson(Map<String, dynamic> json) =>
      ImportBatchEntity(
        id: json['id'] as int,
        type: importTypeFromJson(json['type'] as String?),
        fileName: json['fileName'] as String,
        status: importStatusFromJson(json['status'] as String),
        totalRows: json['totalRows'] as int?,
        successfulRows: json['successfulRows'] as int?,
        failedRows: json['failedRows'] as int?,
        hasErrorReport: json['hasErrorReport'] as bool? ?? false,
        errorCode: json['errorCode'] as String?,
        errorMessage: json['errorMessage'] as String?,
        createdAt: Formatters.parseApiDateTime(json['createdAt'] as String),
        startedAt: _date(json['startedAt']),
        completedAt: _date(json['completedAt']),
      );

  /// `GET /imports/{id}`: the batch plus its first row errors.
  static ImportResultEntity resultFromJson(Map<String, dynamic> json) =>
      ImportResultEntity(
        batch: fromJson(json),
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

  static DateTime? _date(Object? value) =>
      value == null ? null : Formatters.parseApiDateTime(value as String);
}
