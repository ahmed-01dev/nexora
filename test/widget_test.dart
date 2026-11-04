import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/main.dart';

void main() {
  testWidgets('shows safe setup screen when Supabase keys are not provided',
      (tester) async {
    await tester.pumpWidget(const NexoraApp(isConfigured: false));
    expect(find.text('NEXORA'), findsOneWidget);
    expect(find.text('التطبيق جاهز للاتصال بقاعدة البيانات'), findsOneWidget);
    expect(find.textContaining('SUPABASE_ANON_KEY'), findsOneWidget);
  });
}
