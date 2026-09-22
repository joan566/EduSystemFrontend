/// Basic client-side form validators.
///
/// These are UX conveniences only — the backend performs the definitive
/// validation (see API contract §82). Keep these simple and non-duplicative
/// of business rules.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'El email es obligatorio.';
    if (!_email.hasMatch(value.trim())) return 'Ingresa un email válido.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria.';
    if (value.length < 8) return 'Debe tener al menos 8 caracteres.';
    if (value.length > 72) return 'Debe tener máximo 72 caracteres.';
    return null;
  }

  static String? maxLength(String? value, int max, {String field = 'Este campo'}) {
    if (value != null && value.length > max) {
      return '$field debe tener máximo $max caracteres.';
    }
    return null;
  }

  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
