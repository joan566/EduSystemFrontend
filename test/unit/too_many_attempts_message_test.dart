import 'package:edusistem_front/core/extensions/context_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tooManyAttemptsMessage', () {
    test('rounds seconds up to whole minutes', () {
      expect(
        tooManyAttemptsMessage(30),
        'Demasiados intentos. Vuelve a intentarlo en 1 minuto.',
      );
      expect(
        tooManyAttemptsMessage(3540),
        'Demasiados intentos. Vuelve a intentarlo en 59 minutos.',
      );
    });

    test('long waits (daily limit) are shown in hours', () {
      expect(
        tooManyAttemptsMessage(20 * 3600),
        'Demasiados intentos. Vuelve a intentarlo en 20 horas.',
      );
    });

    test('missing Retry-After falls back to "más tarde"', () {
      expect(
        tooManyAttemptsMessage(null),
        'Demasiados intentos. Vuelve a intentarlo más tarde.',
      );
    });
  });
}
