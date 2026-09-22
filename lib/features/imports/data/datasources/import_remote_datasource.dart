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

  Future<ImportResultEntity> uploadStudents({
    required String fileName,
    required List<int> bytes,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _client.postMultipart(
      ApiEndpoints.importStudents,
      formData: formData,
    );
    return ImportBatchModel.resultFromJson(
      response.data as Map<String, dynamic>,
      fallbackFileName: fileName,
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
  /// with just one of them only touches that part. Response shape matches
  /// `uploadStudents` (same `ImportResultResponse` envelope).
  Future<ImportResultEntity> uploadTeachingPeriod({
    required int teachingPeriodId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _client.postMultipart(
      ApiEndpoints.importTeachingPeriod(teachingPeriodId),
      formData: formData,
    );
    return ImportBatchModel.resultFromJson(
      response.data as Map<String, dynamic>,
      fallbackFileName: fileName,
    );
  }

  /// The school-wide bootstrap template (9 sheets: periods, grades,
  /// subjects, groups, classes, students, activities, grades, attendance).
  /// Independent of [uploadTeachingPeriod] — it isn't scoped to any single
  /// teaching period, since it can create the periods/classes themselves.
  Future<BinaryDownload> downloadSchoolSetupTemplate() =>
      _client.getBinary(ApiEndpoints.importSchoolSetupTemplate);

  Future<ImportResultEntity> uploadSchoolSetup({
    required String fileName,
    required List<int> bytes,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _client.postMultipart(
      ApiEndpoints.importSchoolSetup,
      formData: formData,
    );
    return ImportBatchModel.resultFromJson(
      response.data as Map<String, dynamic>,
      fallbackFileName: fileName,
    );
  }
}
