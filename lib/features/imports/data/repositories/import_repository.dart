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

  Future<ImportResultEntity> uploadStudents({
    required String fileName,
    required List<int> bytes,
  }) => _remote.uploadStudents(fileName: fileName, bytes: bytes);

  Future<ApiPage<ImportBatchEntity>> getHistory({int page = 0}) =>
      _remote.getHistory(page: page);

  Future<BinaryDownload> downloadErrorReport(int id) =>
      _remote.downloadErrorReport(id);

  Future<ImportResultEntity> uploadTeachingPeriod({
    required int teachingPeriodId,
    required String fileName,
    required List<int> bytes,
  }) => _remote.uploadTeachingPeriod(
    teachingPeriodId: teachingPeriodId,
    fileName: fileName,
    bytes: bytes,
  );

  Future<BinaryDownload> downloadSchoolSetupTemplate() =>
      _remote.downloadSchoolSetupTemplate();

  Future<ImportResultEntity> uploadSchoolSetup({
    required String fileName,
    required List<int> bytes,
  }) => _remote.uploadSchoolSetup(fileName: fileName, bytes: bytes);

  /// The specific reason a batch failed *before* any row could be
  /// evaluated (wrong file type, missing columns, too many rows...).
  /// [ImportBatchEntity] has no failure-reason field for that path — the
  /// backend only records it in the audit trail — so this is a second call
  /// against `/audit-logs`, not something the batch/history endpoints carry.
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
