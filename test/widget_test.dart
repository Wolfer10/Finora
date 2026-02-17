import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/features/transactions/presentation/transactions_providers.dart';
import 'package:finora/main.dart';

void main() {
  testWidgets('renders Epic 3 shell and default overview tab',
      (WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const FinoraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Monthly Summary'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
  });

  testWidgets('switches to transactions tab', (WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const FinoraApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transactions').first);
    await tester.pumpAndSettle();

    expect(find.text('Transactions'), findsWidgets);
  });
}
