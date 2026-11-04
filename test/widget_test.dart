import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/main.dart';

void main() {
  testWidgets('shows safe setup screen when Supabase keys are missing',
      (tester) async {
    await tester.pumpWidget(const NexoraApp(ready: false));
    expect(find.text('NEXORA محتاج إعداد الاتصال'), findsOneWidget);
    expect(find.textContaining('SUPABASE_ANON_KEY'), findsOneWidget);
  });
}
