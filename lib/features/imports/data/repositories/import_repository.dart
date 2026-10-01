import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../../audit/data/datasources/audit_remote_datasource.dart';
import '../../domain/entities/import_batch_entity.dart';
import '../datasources/import_remote_datasource.dart';

class ImportRepository {
  ImportRepository(this._remote, this._audit);

  final ImportRemoteDataSource _remote;
  final AuditRemoteDataSource _audit;

  Future<BinaryDownload> downloadTemplate() => _remote.downloadTemplate();

  Future<ImportBatchEntity> uploadStudents({
    required String fileName,
    required List<int> bytes,
    ProgressCallback? onSendProgress,
  }) => _remote.uploadStudents(
    fileName: fileName,
    bytes: bytes,
    onSendProgress: onSendProgress,
  );

  Future<ImportResultEntity> getImport(int id) => _remote.getImport(id);

  Future<ApiPage<ImportBatchEntity>> getHistory({int page = 0}) =>
      _remote.getHistory(page: page);

  Future<BinaryDownload> downloadErrorReport(int id) =>
      _remote.downloadErrorReport(id);

  Future<ImportBatchEntity> uploadTeachingPeriod({
    required int teachingPeriodId,
    required String fileName,
    required List<int> bytes,
    ProgressCallback? onSendProgress,
  }) => _remote.uploadTeachingPeriod(
    teachingPeriodId: teachingPeriodId,
    fileName: fileName,
    bytes: bytes,
    onSendProgress: onSendProgress,
  );

  Future<BinaryDownload> downloadSchoolSetupTemplate() =>
      _remote.downloadSchoolSetupTemplate();

  Future<ImportBatchEntity> uploadSchoolSetup({
    required String fileName,
    required List<int> bytes,
    ProgressCallback? onSendProgress,
  }) => _remote.uploadSchoolSetup(
    fileName: fileName,
    bytes: bytes,
    onSendProgress: onSendProgress,
  );

  /// Why an *old* batch failed before any row was evaluated. Imports now
  /// carry [ImportBatchEntity.errorMessage]; batches from before that only
  /// recorded the reason in the audit trail, so this reads `/audit-logs`.
  Future<String?> getFailureReason(int batchId) async {
    final page = await _audit.getPage(
      entityType: 'ImportBatch',
      entityId: batchId,
      size: 1,
    );
    if (page.content.isEmpty) return null;
    final log = page.content.first;
    return log.isSuccess ? null : log.details;
  }
}
