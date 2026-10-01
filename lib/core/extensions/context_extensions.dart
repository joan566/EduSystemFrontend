import 'package:flutter/material.dart';

import '../errors/app_exception.dart';
import '../theme/app_colors.dart';

enum _NotifKind { success, error, warning, info }

/// Theme shortcuts and the app-wide notification system (§62: consistent
/// success/error/warning/info feedback instead of ad hoc SnackBars).
extension AppContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;

  void showSuccess(String message, {Duration? duration}) =>
      _showNotif(this, _NotifKind.success, message, duration: duration);
  void showError(String message) => _showNotif(this, _NotifKind.error, message);
  void showWarning(String message) => _showNotif(this, _NotifKind.warning, message);
  void showInfo(String message) => _showNotif(this, _NotifKind.info, message);

  /// Maps an [AppException] to a user-facing message and shows it. Prefer
  /// this over showing `exception.message` directly for anything the user
  /// can act on.
  void showApiError(AppException exception) {
    _showNotif(this, _NotifKind.error, _messageFor(exception));
  }

  String _messageFor(AppException e) {
    switch (e.code) {
      case AppErrorCode.network:
        return 'No pudimos conectar con el servidor. Verifica tu conexión.';
      case AppErrorCode.timeout:
        return 'La solicitud tardó demasiado. Inténtalo de nuevo.';
      case AppErrorCode.invalidCredentials:
        return 'Correo o contraseña incorrectos.';
      case AppErrorCode.unauthorized:
      case AppErrorCode.invalidRefreshToken:
        return 'Tu sesión ha expirado. Inicia sesión de nuevo.';
      case AppErrorCode.accessDenied:
        return 'No tienes permisos para realizar esta acción.';
      case AppErrorCode.resourceNotFound:
        return 'No se encontró el recurso solicitado.';
      case AppErrorCode.fileTooLarge:
        return 'El archivo supera el tamaño máximo permitido (60 MB).';
      case AppErrorCode.unsupportedMediaType:
        return 'El formato de archivo no es compatible.';
      case AppErrorCode.tooManyLoginAttempts:
      case AppErrorCode.tooManyRegistrations:
      case AppErrorCode.tooManyPasswordResetRequests:
      case AppErrorCode.tooManyEmailVerificationRequests:
        return tooManyAttemptsMessage(e.retryAfterSeconds);
      case AppErrorCode.emailNotVerified:
        return 'Debes verificar tu correo antes de iniciar sesión.';
      case AppErrorCode.invalidVerificationCode:
        return 'El código no es válido o ya expiró.';
      case AppErrorCode.invalidCurrentPassword:
        return 'La contraseña actual es incorrecta.';
      case AppErrorCode.gradeHasGroups:
        return 'No puedes eliminar este grado porque tiene cursos asociados.';
      case AppErrorCode.groupHasDependents:
        return 'No puedes eliminar este curso porque tiene estudiantes o '
            'clases asociadas.';
      case AppErrorCode.subjectHasTeachingAssignments:
        return 'No puedes eliminar esta materia porque tiene clases '
            'asociadas.';
      case AppErrorCode.academicPeriodInUse:
        return 'No puedes eliminar este periodo porque tiene clases '
            'asociadas.';
      case AppErrorCode.errorReportNotFound:
        return 'El informe ya no está disponible.';
      case AppErrorCode.internalError:
        return 'Ocurrió un error en el servidor. Inténtalo más tarde.';
      default:
        if (e.isBusinessRule || e.isConflict) return e.message;
        return e.message;
    }
  }
}

void _showNotif(
  BuildContext context,
  _NotifKind kind,
  String message, {
  Duration? duration,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final (Color bg, Color fg, IconData icon) = switch (kind) {
    _NotifKind.success => (AppColors.success, Colors.white, Icons.check_circle_outline),
    _NotifKind.error => (AppColors.error, Colors.white, Icons.error_outline),
    _NotifKind.warning => (AppColors.warning, Colors.white, Icons.warning_amber_rounded),
    _NotifKind.info => (AppColors.info, Colors.white, Icons.info_outline),
  };

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration ?? const Duration(milliseconds: 4000),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      content: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: fg)),
          ),
        ],
      ),
    ),
  );
}

/// Copy for every 429 (login, registro, recuperación de contraseña),
/// rounded up from `Retry-After` so it never promises too short a wait.
/// Nothing retries automatically; the user decides when to try again.
String tooManyAttemptsMessage(int? retryAfterSeconds) {
  const prefix = 'Demasiados intentos. Vuelve a intentarlo';
  final seconds = retryAfterSeconds;
  if (seconds == null || seconds <= 0) return '$prefix más tarde.';
  final minutes = (seconds / 60).ceil();
  if (minutes <= 90) {
    return '$prefix en $minutes ${minutes == 1 ? 'minuto' : 'minutos'}.';
  }
  final hours = (minutes / 60).ceil();
  return '$prefix en $hours horas.';
}
