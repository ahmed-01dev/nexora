import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/app_error.dart';

void main() {
  group('AppErrorService.message', () {
    test('maps network failures to a retryable Arabic message', () {
      expect(
        AppErrorService.message(Exception('SocketException: failed host lookup')),
        'مفيش اتصال بالسيرفر. اتأكد من الإنترنت وجرب تاني.',
      );
    });

    test('maps authentication failures without exposing backend details', () {
      expect(
        AppErrorService.message(Exception('JWT not authenticated')),
        'انتهت جلسة الدخول. سجّل الدخول مرة تانية.',
      );
    });

    test('maps RLS failures to a safe permission message', () {
      expect(
        AppErrorService.message(Exception('row-level security policy violation')),
        'مش مسموح بالعملية دي على الحساب الحالي.',
      );
    });

    test('uses a generic safe message for unknown backend errors', () {
      expect(
        AppErrorService.message(Exception('sensitive backend response')),
        'حصلت مشكلة أثناء تنفيذ الطلب. حاول مرة تانية.',
      );
    });

    test('does not write raw exception text to debug logs', () {
      final messages = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) messages.add(message);
      };
      try {
        AppErrorService.report(
          Exception('user@example.com secret-response-token'),
          null,
          source: 'privacy_test',
        );
      } finally {
        debugPrint = previousDebugPrint;
      }
      expect(messages.join(' '), contains('Exception'));
      expect(messages.join(' '), isNot(contains('user@example.com')));
      expect(messages.join(' '), isNot(contains('secret-response-token')));
    });
  });
}
