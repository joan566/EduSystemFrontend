/// Centralized environment configuration.
///
/// Values are injected at build/run time via `--dart-define-from-file`,
/// e.g. `flutter run --dart-define-from-file=env/development.json`.
/// See `env/development.json.example` and `env/production.json.example`.
class AppConfig {
  AppConfig._();

  /// Base URL of the EduSistem REST API, without trailing slash and
  /// without the `/api/v1` prefix (that is added by [apiBaseUrl]).
  static const String _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'http://192.168.0.106:8080',
  );

  /// Full base URL for API calls, e.g. http://localhost:8080/api/v1
  static String get apiBaseUrl => '$_host/api/v1';

  static const String environmentName = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isProduction => environmentName == 'production';

  /// Connection/receive timeouts for the HTTP client.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Longer timeout for submission uploads (image processing).
  static const Duration uploadTimeout = Duration(seconds: 60);

  /// Maximum upload size accepted by the backend (15 MB), used for
  /// client-side pre-validation before sending a request.
  static const int maxUploadSizeBytes = 15 * 1024 * 1024;
}
