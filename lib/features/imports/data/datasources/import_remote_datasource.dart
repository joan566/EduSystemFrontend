import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/list_state.dart';
import '../../domain/entities/import_batch_entity.dart';
import '../models/import_batch_model.dart';

class ImportRemoteDataSource {
  ImportRemoteDataSource(this._client);

  final ApiClient _client;

  Future<BinaryDownload> downloadTemplate() =>
      _client.getBinary(ApiEndpoints.importStudentsTemplate);

  /// Uploads go into a background queue: the answer (202) is the import in
  /// `QUEUED`; its result is read later with [getImport]. File-level
  /// validation (empty, not .xlsx, too large, import already running)
  /// still fails right here.
  Future<ImportBatchEntity> uploadStudents({
    required String fileName,
    required List<int> bytes,
    ProgressCallback? onSendProgress,
  }) => _upload(
    ApiEndpoints.importStudents,
    fileName: fileName,
    bytes: bytes,
    onSendProgress: onSendProgress,
  );

  /// One import with its first row errors; polled until it finishes.
  Future<ImportResultEntity> getImport(int id) async {
    final response = await _client.get(ApiEndpoints.importById(id));
    return ImportBatchModel.resultFromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ApiPage<ImportBatchEntity>> getHistory({int page = 0}) async {
    final response = await _client.get(
      ApiEndpoints.imports,
      queryParameters: {'page': page, 'size': 20},
    );
    return ApiPage.fromJson(
      response.data as Map<String, dynamic>,
      ImportBatchModel.fromJson,
    );
  }

  Future<BinaryDownload> downloadErrorReport(int id) =>
      _client.getBinary(ApiEndpoints.importErrorReport(id));

  /// Uploads the combined Students/Grades/Attendance workbook for a
  /// teaching period. Sheets are all optional server-side — a workbook
  /// with just one of them only touches that part.
  Future<ImportBatchEntity> uploadTeachingPeriod({
    required int teachingPeriodId,
    required String fileName,
    required List<int> bytes,
    ProgressCallback? onSendProgress,
  }) => _upload(
    ApiEndpoints.importTeachingPeriod(teachingPeriodId),
    fileName: fileName,
    bytes: bytes,
    onSendProgress: onSendProgress,
  );

  /// The school-wide bootstrap template (9 sheets: periods, grades,
  /// subjects, groups, classes, students, activities, grades, attendance).
  /// Independent of [uploadTeachingPeriod] — it isn't scoped to any single
  /// teaching period, since it can create the periods/classes themselves.
  Future<BinaryDownload> downloadSchoolSetupTemplate() =>
      _client.getBinary(ApiEndpoints.importSchoolSetupTemplate);

  Future<ImportBatchEntity> uploadSchoolSetup({
    required String fileName,
    required List<int> bytes,
    ProgressCallback? onSendProgress,
  }) => _upload(
    ApiEndpoints.importSchoolSetup,
    fileName: fileName,
    bytes: bytes,
    onSendProgress: onSendProgress,
  );

  Future<ImportBatchEntity> _upload(
    String path, {
    required String fileName,
    required List<int> bytes,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _client.postMultipart(
      path,
      formData: formData,
      onSendProgress: onSendProgress,
    );
    return ImportBatchModel.fromJson(response.data as Map<String, dynamic>);
  }
}
