import 'package:flutter_test/flutter_test.dart';

import 'package:finora/main.dart';

void main() {
  testWidgets('renders dashboard shell baseline', (WidgetTester tester) async {
    await tester.pumpWidget(const FinoraApp());

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('Net Balance'), findsOneWidget);
  });

  testWidgets('changes selected month from selector chip',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FinoraApp());

    await tester.tap(find.text('Jan 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Jan 2026'), findsWidgets);
  });
}
