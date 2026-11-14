import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wimalasooriya_farm/main.dart';

void main() {
  testWidgets('App smoke test builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WimalasooriyaFarmApp(),
      ),
    );
    expect(find.byType(WimalasooriyaFarmApp), findsOneWidget);
  });
}
