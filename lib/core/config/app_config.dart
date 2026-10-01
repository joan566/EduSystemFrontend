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
    defaultValue: 'https://edusystembackend.onrender.com',
  );

  /// Full base URL for API calls, e.g. http://localhost:8080/api/v1
  static String get apiBaseUrl => '$_host/api/v1';

  static const String environmentName = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isProduction => environmentName == 'production';

  /// Whether the app checks the backend's version policy (`/app/version`)
  /// at launch. Off only for local setups whose backend lacks the endpoint.
  static const bool versionCheckEnabled = bool.fromEnvironment(
    'VERSION_CHECK_ENABLED',
    defaultValue: true,
  );

  /// Optional override for where "Actualizar" sends the user on Android.
  /// Empty: the Google Play listing of the installed package.
  static const String updateUrl = String.fromEnvironment('UPDATE_URL');

  /// How old a successful version check may get before returning to the
  /// foreground checks again.
  static const Duration versionRecheckAfter = Duration(hours: 6);

  /// Connection/receive timeouts for the HTTP client.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Longer timeout for submission uploads (image processing).
  static const Duration uploadTimeout = Duration(seconds: 60);

  /// Maximum upload size accepted by the backend (60 MB), used for
  /// client-side pre-validation before sending a request.
  static const int maxUploadSizeBytes = 60 * 1024 * 1024;

  /// Maximum pages the backend accepts in one scanned-sheets PDF batch.
  static const int maxBatchPdfPages = 200;

  /// How often a running submission batch is polled for progress.
  static const Duration batchPollInterval = Duration(milliseconds: 1500);
}
