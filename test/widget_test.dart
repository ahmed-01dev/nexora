import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/main.dart';

void main() {
  testWidgets('shows the safe setup screen when Supabase is unavailable',
      (tester) async {
    await tester.pumpWidget(const NexoraApp(ready: false));
    expect(find.text('تعذر الاتصال بخدمات NEXORA'), findsOneWidget);
    expect(
      find.textContaining('تحقق من اتصال الإنترنت وإعدادات Supabase'),
      findsOneWidget,
    );
  });

  testWidgets('shows the supplied startup error on the setup screen',
      (tester) async {
    await tester.pumpWidget(const NexoraApp(
      ready: false,
      startupError: 'Invalid Supabase URL',
    ));
    expect(find.textContaining('Invalid Supabase URL'), findsOneWidget);
  });
}
