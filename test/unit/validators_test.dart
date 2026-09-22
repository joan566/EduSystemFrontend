import 'package:edusistem_front/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty value', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejects a value without an @', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('accepts a well-formed email', () {
      expect(Validators.email('teacher@school.edu'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects passwords shorter than 8 characters', () {
      expect(Validators.password('short'), isNotNull);
    });

    test('rejects passwords longer than 72 characters', () {
      expect(Validators.password('a' * 73), isNotNull);
    });

    test('accepts an 8-72 character password', () {
      expect(Validators.password('validPassword123'), isNull);
    });
  });

  group('Validators.maxLength', () {
    test('rejects a value over the limit', () {
      expect(Validators.maxLength('123456', 5), isNotNull);
    });

    test('accepts a value within the limit', () {
      expect(Validators.maxLength('12345', 5), isNull);
    });

    test('treats a null value as valid (use required separately)', () {
      expect(Validators.maxLength(null, 5), isNull);
    });
  });

  group('Validators.combine', () {
    test('returns the first failing validator message', () {
      final combined = Validators.combine([
        (v) => Validators.required(v, field: 'Name'),
        (v) => Validators.maxLength(v, 3, field: 'Name'),
      ]);
      expect(combined(''), contains('obligatorio'));
      expect(combined('abcd'), contains('máximo'));
      expect(combined('abc'), isNull);
    });
  });
}
