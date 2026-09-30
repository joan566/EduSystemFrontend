/// A single field-level validation error, as returned by the backend's
/// `errors[]` array on 400 validation responses.
class FieldError {
  const FieldError({required this.field, required this.message});

  final String field;
  final String message;
}

/// Normalized representation of every error the app can encounter,
/// whether it comes from the backend's JSON error envelope, a network
/// failure, or an unexpected client-side problem.
///
/// UI code should branch on [code] (stable, backend-defined) rather than
/// [message] (English, may change).
class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fieldErrors = const [],
    this.retryAfterSeconds,
  });

  /// Stable backend error code, e.g. `INVALID_CREDENTIALS`,
  /// `RESOURCE_NOT_FOUND`. One of the [AppErrorCode] constants for known
  /// cases, or the raw backend code otherwise.
  final String code;

  /// Human-readable message. English from the backend for business errors;
  /// localized for client-side/network errors. Only used as a fallback —
  /// prefer mapping [code] to a localized string in the UI.
  final String message;

  final int? statusCode;
  final List<FieldError> fieldErrors;

  /// Present for 429 responses (`Retry-After` header, in seconds).
  final int? retryAfterSeconds;

  bool get isValidation => statusCode == 400 && fieldErrors.isNotEmpty;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isBusinessRule => statusCode == 422;
  bool get isRateLimited => statusCode == 429;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isNetwork => code == AppErrorCode.network || code == AppErrorCode.timeout;

  @override
  String toString() => 'AppException($code, status=$statusCode, "$message")';
}

/// Well-known error codes. Backend business codes not listed here still
/// flow through as raw strings in [AppException.code] — this is not an
/// exhaustive enum on purpose (see API contract notes on forward
/// compatibility).
class AppErrorCode {
  AppErrorCode._();

  static const String network = 'NETWORK_ERROR';
  static const String timeout = 'TIMEOUT';
  static const String unknown = 'UNKNOWN_ERROR';
  static const String cancelled = 'CANCELLED';

  static const String invalidRequest = 'INVALID_REQUEST';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String invalidRefreshToken = 'INVALID_REFRESH_TOKEN';
  static const String accessDenied = 'ACCESS_DENIED';
  static const String resourceNotFound = 'RESOURCE_NOT_FOUND';
  static const String fileTooLarge = 'FILE_TOO_LARGE';
  static const String unsupportedMediaType = 'UNSUPPORTED_MEDIA_TYPE';
  static const String tooManyLoginAttempts = 'TOO_MANY_LOGIN_ATTEMPTS';
  static const String tooManyRegistrations = 'TOO_MANY_REGISTRATIONS';
  static const String tooManyPasswordResetRequests =
      'TOO_MANY_PASSWORD_RESET_REQUESTS';
  static const String invalidCurrentPassword = 'INVALID_CURRENT_PASSWORD';
  static const String gradeHasGroups = 'GRADE_HAS_GROUPS';
  static const String groupHasDependents = 'GROUP_HAS_DEPENDENTS';
  static const String subjectHasTeachingAssignments =
      'SUBJECT_HAS_TEACHING_ASSIGNMENTS';
  static const String academicPeriodInUse = 'ACADEMIC_PERIOD_IN_USE';
  static const String errorReportNotFound = 'ERROR_REPORT_NOT_FOUND';
  static const String internalError = 'INTERNAL_ERROR';
}
