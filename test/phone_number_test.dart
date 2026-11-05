import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/features/auth/phone_number.dart';

void main() {
  group('normalizeNexoraPhone', () {
    test('normalizes Egyptian local mobile numbers', () {
      expect(normalizeNexoraPhone('01012345678'), '+201012345678');
      expect(normalizeNexoraPhone('  011 2345 6789 '), '+201123456789');
    });

    test('normalizes Arabic-Indic and Persian digits', () {
      expect(normalizeNexoraPhone('٠١٠١٢٣٤٥٦٧٨'), '+201012345678');
      expect(normalizeNexoraPhone('۰۱۰۱۲۳۴۵۶۷۸'), '+201012345678');
    });

    test('accepts Egyptian international numbers', () {
      expect(normalizeNexoraPhone('+201012345678'), '+201012345678');
      expect(normalizeNexoraPhone('00201012345678'), '+201012345678');
    });

    test('rejects malformed numbers without stripping invalid characters', () {
      expect(normalizeNexoraPhone('123'), isNull);
      expect(normalizeNexoraPhone('abcdefghijk'), isNull);
      expect(normalizeNexoraPhone('+01234567890'), isNull);
      expect(normalizeNexoraPhone('01012abc678'), isNull);
      expect(normalizeNexoraPhone('01012345678+'), isNull);
    });
  });
}
