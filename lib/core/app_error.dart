import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized, privacy-conscious error reporting for NEXORA.
/// Never writes passwords, access tokens, email addresses or request headers.
class AppErrorService {
  AppErrorService._();

  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      report(details.exception, details.stack, source: 'flutter');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack, source: 'platform');
      return true;
    };
  }

  static void report(Object error, StackTrace? stack, {String source = 'app'}) {
    debugPrint('[NEXORA][$source] $error');
    if (stack != null) debugPrintStack(stackTrace: stack);
  }

  static String message(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('socketexception') ||
        value.contains('failed host lookup') ||
        value.contains('network is unreachable')) {
      return 'مفيش اتصال بالسيرفر. اتأكد من الإنترنت وجرب تاني.';
    }
    if (value.contains('jwt') || value.contains('not authenticated')) {
      return 'انتهت جلسة الدخول. سجّل الدخول مرة تانية.';
    }
    if (value.contains('duplicate key') || value.contains('unique constraint')) {
      return 'البيانات دي مستخدمة بالفعل. جرّب قيمة مختلفة.';
    }
    if (value.contains('permission denied') ||
        value.contains('row-level security') ||
        value.contains('rls')) {
      return 'مش مسموح بالعملية دي على الحساب الحالي.';
    }
    return 'حصلت مشكلة أثناء تنفيذ الطلب. حاول مرة تانية.';
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.title,
    required this.onRetry,
    this.error,
  });

  final String title;
  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error == null ? 'اسحب للتحديث أو حاول مرة تانية.' : AppErrorService.message(error!),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
