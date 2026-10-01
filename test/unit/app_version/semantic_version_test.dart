import 'package:edusistem_front/features/app_version/domain/entities/semantic_version.dart';
import 'package:flutter_test/flutter_test.dart';

SemanticVersion v(String raw) => SemanticVersion.tryParse(raw)!;

void main() {
  group('comparison is numeric', () {
    test('1.0.0 == 1.0.0', () {
      expect(v('1.0.0'), v('1.0.0'));
      expect(v('1.0.0').compareTo(v('1.0.0')), 0);
      expect(v('1.0.0').hashCode, v('1.0.0').hashCode);
    });

    test('1.0.0 < 1.1.0', () => expect(v('1.0.0') < v('1.1.0'), isTrue));
    test('1.1.0 < 1.2.0', () => expect(v('1.1.0') < v('1.2.0'), isTrue));

    test('1.9.0 < 1.10.0 (not lexicographic)', () {
      expect(v('1.9.0') < v('1.10.0'), isTrue);
      expect(v('1.10.0') > v('1.9.0'), isTrue);
    });

    test('2.0.0 > 1.9.9', () => expect(v('2.0.0') > v('1.9.9'), isTrue));

    test('patch decides when major and minor match', () {
      expect(v('1.2.3') < v('1.2.10'), isTrue);
      expect(v('1.2.3') <= v('1.2.3'), isTrue);
      expect(v('1.2.3') >= v('1.2.3'), isTrue);
    });
  });

  group('tryParse', () {
    test('accepts X.Y.Z', () {
      expect(v('1.0.0').toString(), '1.0.0');
      expect(v('10.20.30').toString(), '10.20.30');
      expect(v(' 1.2.0 ').toString(), '1.2.0');
    });

    test('drops the Flutter build number', () {
      expect(v('1.2.0+5'), v('1.2.0'));
      expect(v('1.2.0+10'), v('1.2.0+5'));
      expect(v('1.2.0+5').toString(), '1.2.0');
    });

    for (final raw in [
      '',
      '1',
      '1.2',
      '1.2.3.4',
      'a.b.c',
      '1.-2.0',
      '1.2.0-beta',
      'v1.2.0',
      '1.2.x',
      '+5',
    ]) {
      test('rejects "$raw"', () => expect(SemanticVersion.tryParse(raw), isNull));
    }
  });
}
