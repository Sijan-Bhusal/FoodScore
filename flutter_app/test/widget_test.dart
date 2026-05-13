import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:food_score/app/app.dart';

void main() {
  testWidgets('app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FoodScoreApp()));
    await tester.pumpAndSettle();

    expect(find.text('Open Food Facts'), findsOneWidget);
  });
}
