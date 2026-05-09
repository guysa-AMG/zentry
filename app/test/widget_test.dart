import 'package:zentry/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
  
    await tester.pumpWidget(const ProviderScope(child: ZentryApp()));
    expect(find.text('DRIVING MODE'), findsOneWidget);
  });
}
