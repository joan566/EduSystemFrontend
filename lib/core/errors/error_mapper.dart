import 'package:dio/dio.dart';
import 'app_exception.dart';

/// Converts a [DioException] (or any thrown error) into an [AppException],
/// following the backend's standard error envelope:
/// `{ timestamp, status, code, message, path, errors[] }`.
class ErrorMapper {
  ErrorMapper._();

  static AppException fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          code: AppErrorCode.timeout,
          message: 'The request took too long to respond.',
        );
      case DioExceptionType.connectionError:
        return const AppException(
          code: AppErrorCode.network,
          message: 'Could not connect to the server.',
        );
      case DioExceptionType.cancel:
        return const AppException(
          code: AppErrorCode.cancelled,
          message: 'Request cancelled.',
        );
      case DioExceptionType.badCertificate:
        return const AppException(
          code: AppErrorCode.network,
          message: 'Secure connection could not be established.',
        );
      case DioExceptionType.badResponse:
        return _fromResponse(e);
      case DioExceptionType.unknown:
      default:
        return const AppException(
          code: AppErrorCode.network,
          message: 'Could not connect to the server.',
        );
    }
  }

  static AppException _fromResponse(DioException e) {
    final response = e.response;
    final status = response?.statusCode;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final code = data['code'] as String? ?? AppErrorCode.unknown;
      final message = data['message'] as String? ?? 'Unexpected error.';
      final rawErrors = data['errors'];
      final fieldErrors = <FieldError>[];
      if (rawErrors is List) {
        for (final item in rawErrors) {
          if (item is Map<String, dynamic>) {
            fieldErrors.add(
              FieldError(
                field: item['field'] as String? ?? '',
                message: item['message'] as String? ?? '',
              ),
            );
          } else if (item is String && item.trim().isNotEmpty) {
            fieldErrors.add(FieldError(field: '', message: item));
          }
        }
      }

      int? retryAfter;
      final retryHeader = response?.headers.value('Retry-After');
      if (retryHeader != null) {
        retryAfter = int.tryParse(retryHeader);
      }

      return AppException(
        code: code,
        message: message,
        statusCode: status,
        fieldErrors: fieldErrors,
        retryAfterSeconds: retryAfter,
      );
    }

    return AppException(
      code: AppErrorCode.unknown,
      message: 'Unexpected server error.',
      statusCode: status,
    );
  }
}
