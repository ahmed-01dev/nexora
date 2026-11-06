import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/features/auth/email_auth_validation.dart';

void main() {
  group('NexoraEmailAuthValidation.email', () {
    test('accepts a valid email with surrounding whitespace', () {
      expect(NexoraEmailAuthValidation.email('  user@example.com  '), isNull);
    });

    test('rejects empty and malformed email values', () {
      for (final value in ['', 'plain-text', 'user@', '@example.com', 'a b@example.com']) {
        expect(NexoraEmailAuthValidation.email(value), isNotNull, reason: value);
      }
    });
  });

  group('NexoraEmailAuthValidation.password', () {
    test('requires a strong password at registration', () {
      expect(NexoraEmailAuthValidation.password('short1A', registering: true), isNotNull);
      expect(NexoraEmailAuthValidation.password('abcdefghijkl', registering: true), isNotNull);
      expect(NexoraEmailAuthValidation.password('123456789012', registering: true), isNotNull);
      expect(NexoraEmailAuthValidation.password('NexoraSecure123', registering: true), isNull);
    });

    test('allows existing passwords of at least eight characters at sign-in', () {
      expect(NexoraEmailAuthValidation.password('12345678', registering: false), isNull);
      expect(NexoraEmailAuthValidation.password('1234567', registering: false), isNotNull);
    });

    test('rejects an empty password', () {
      expect(NexoraEmailAuthValidation.password('', registering: false), isNotNull);
    });
  });

  test('display name must contain at least two non-whitespace characters', () {
    expect(NexoraEmailAuthValidation.displayName(' A '), isNotNull);
    expect(NexoraEmailAuthValidation.displayName('  '), isNotNull);
    expect(NexoraEmailAuthValidation.displayName('Ahmed'), isNull);
  });
}
