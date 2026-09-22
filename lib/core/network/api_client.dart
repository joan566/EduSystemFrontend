import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// A binary download result: raw bytes plus the filename the backend
/// suggested via `Content-Disposition`.
class BinaryDownload {
  const BinaryDownload({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final List<int> bytes;
  final String fileName;
  final String? contentType;
}

/// Centralized HTTP client for the whole app. All REST calls go through
/// here — features never construct their own [Dio] instance or reference
/// `AppConfig.apiBaseUrl` directly.
///
/// Responsibilities: base URL, JWT attachment + refresh (via
/// [AuthInterceptor]), timeouts, multipart uploads, binary downloads, and
/// translating every failure into an [AppException].
class ApiClient {
  ApiClient({required Future<void> Function() onSessionExpired})
    : _tokenStorage = TokenStorage(),
      _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
    _authInterceptor = AuthInterceptor(
      tokenStorage: _tokenStorage,
      onSessionExpired: onSessionExpired,
    );
    _authInterceptor.attachDio(_dio);
    _dio.interceptors.add(_authInterceptor);
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          logPrint: (obj) => debugPrint('[HTTP] $obj'),
        ),
      );
    }
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  late final AuthInterceptor _authInterceptor;

  TokenStorage get tokenStorage => _tokenStorage;

  /// Loads a persisted session (if any) into memory so requests are
  /// authenticated immediately after app start, without waiting on a
  /// secure-storage read per call.
  Future<AuthTokens?> restoreSession() async {
    final tokens = await _tokenStorage.read();
    _authInterceptor.setTokens(tokens);
    return tokens;
  }

  AuthTokens? get currentTokens => _authInterceptor.currentTokens;

  Future<void> setSession(AuthTokens tokens) async {
    _authInterceptor.setTokens(tokens);
    await _tokenStorage.save(tokens);
  }

  Future<void> clearSession() async {
    _authInterceptor.setTokens(null);
    await _tokenStorage.clear();
  }

  Future<T> _run<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        code: AppErrorCode.unknown,
        message: 'An unexpected error occurred.',
      );
    }
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _run(
    () => _dio.get(path, queryParameters: _clean(queryParameters)),
  );

  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _run(() => _dio.post(path, data: data));

  Future<Response<dynamic>> put(String path, {Object? data}) =>
      _run(() => _dio.put(path, data: data));

  Future<Response<dynamic>> patch(String path, {Object? data}) =>
      _run(() => _dio.patch(path, data: data));

  Future<Response<dynamic>> delete(String path) =>
      _run(() => _dio.delete(path));

  Future<Response<dynamic>> postMultipart(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
  }) => _run(
    () => _dio.post(
      path,
      data: formData,
      queryParameters: _clean(queryParameters),
      onSendProgress: onSendProgress,
    ),
  );

  /// GETs a binary payload (PDF, XLSX) and extracts the filename from the
  /// `Content-Disposition` header exposed by the backend.
  Future<BinaryDownload> getBinary(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _run(() async {
    final response = await _dio.get<List<int>>(
      path,
      queryParameters: _clean(queryParameters),
      options: Options(responseType: ResponseType.bytes),
    );
    final disposition = response.headers.value('content-disposition');
    final fileName = _parseFileName(disposition) ?? 'download';
    return BinaryDownload(
      bytes: response.data ?? const [],
      fileName: fileName,
      contentType: response.headers.value('content-type'),
    );
  });

  /// GETs binary image bytes (submission photo review) without caching.
  Future<List<int>> getImageBytes(String path) => _run(() async {
    final response = await _dio.get<List<int>>(
      path,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Cache-Control': 'no-cache'},
      ),
    );
    return response.data ?? const [];
  });

  Map<String, dynamic>? _clean(Map<String, dynamic>? params) {
    if (params == null) return null;
    final result = <String, dynamic>{};
    for (final entry in params.entries) {
      if (entry.value != null) result[entry.key] = entry.value;
    }
    return result;
  }

  String? _parseFileName(String? disposition) {
    if (disposition == null) return null;
    final match = RegExp(
      r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''',
    ).firstMatch(disposition);
    return match?.group(1);
  }
}
