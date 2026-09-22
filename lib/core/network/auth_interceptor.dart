import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';

/// Endpoints that never carry an Authorization header and never trigger a
/// refresh-and-retry cycle on 401 (they ARE the auth flow).
const _publicPaths = <String>[
  '/auth/register',
  '/auth/login',
  '/auth/refresh',
  '/auth/forgot-password',
  '/auth/verify-code',
  '/auth/reset-password',
];

/// Attaches the current access token to every authenticated request and
/// transparently refreshes an expired session on 401, retrying the
/// original request exactly once. Concurrent 401s share a single in-flight
/// refresh via [_refreshCompleter].
///
/// The access/refresh token pair lives in memory here (set by whoever owns
/// the session — [AuthProvider]) to avoid an async secure-storage read on
/// every request; [TokenStorage] is only touched to persist changes.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Future<void> Function() onSessionExpired,
  }) : _tokenStorage = tokenStorage,
       _onSessionExpired = onSessionExpired,
       _refreshDio = Dio(
         BaseOptions(
           baseUrl: AppConfig.apiBaseUrl,
           connectTimeout: AppConfig.connectTimeout,
           receiveTimeout: AppConfig.receiveTimeout,
           headers: const {'Content-Type': 'application/json'},
         ),
       );

  final TokenStorage _tokenStorage;
  final Future<void> Function() _onSessionExpired;
  final Dio _refreshDio;

  /// The intercepted client, used to retry a request after a successful
  /// refresh. Set once by [ApiClient] right after construction.
  Dio? _dio;
  void attachDio(Dio dio) => _dio = dio;

  AuthTokens? _tokens;
  Completer<bool>? _refreshCompleter;

  void setTokens(AuthTokens? tokens) => _tokens = tokens;
  AuthTokens? get currentTokens => _tokens;

  bool _isPublic(String path) =>
      _publicPaths.any((p) => path.contains(p));

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!_isPublic(options.path) && _tokens != null) {
      options.headers['Authorization'] = 'Bearer ${_tokens!.accessToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final request = err.requestOptions;

    final shouldAttemptRefresh =
        response?.statusCode == 401 &&
        !_isPublic(request.path) &&
        request.extra['retried'] != true &&
        _tokens != null;

    if (!shouldAttemptRefresh) {
      handler.next(err);
      return;
    }

    final refreshed = await _refresh();
    if (!refreshed || _dio == null) {
      handler.next(err);
      return;
    }

    try {
      final retryOptions = request.copyWith(
        extra: {...request.extra, 'retried': true},
      );
      retryOptions.headers['Authorization'] = 'Bearer ${_tokens!.accessToken}';
      final response = await _dio!.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Ensures only one refresh call is in flight at a time; concurrent
  /// callers await the same result.
  Future<bool> _refresh() {
    final existing = _refreshCompleter;
    if (existing != null) return existing.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    _doRefresh().then(completer.complete).catchError((_) {
      completer.complete(false);
    }).whenComplete(() => _refreshCompleter = null);
    return completer.future;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = _tokens?.refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data!;
      final expiresIn = data['expiresIn'] as int? ?? 3600;
      final newTokens = AuthTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      );
      _tokens = newTokens;
      await _tokenStorage.save(newTokens);
      return true;
    } catch (_) {
      _tokens = null;
      await _tokenStorage.clear();
      await _onSessionExpired();
      return false;
    }
  }
}
