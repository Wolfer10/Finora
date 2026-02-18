import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/features/transactions/data/recurring_rule_repository_sql.dart';
import 'package:finora/features/transactions/domain/recurring_rule.dart';
import 'package:finora/features/transactions/domain/transaction.dart';

void main() {
  late AppDatabase db;
  late RecurringRuleRepositorySql repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = RecurringRuleRepositorySql(db);
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  test('create/watch/listDue/update/softDelete lifecycle', () async {
    final now = DateTime(2026, 2, 18, 12, 0);
    await _insertDependencies(db, now: now);

    final rule = RecurringRule(
      id: 'rule-1',
      type: TransactionType.expense,
      accountId: 'acc-1',
      categoryId: 'cat-1',
      toAccountId: null,
      amount: 120,
      note: 'Gym',
      startDate: DateTime(2026, 2, 1),
      endDate: null,
      nextRunAt: DateTime(2026, 2, 10),
      recurrenceUnit: RecurrenceUnit.monthly,
      recurrenceInterval: 1,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );

    await repository.create(rule);

    final active = await repository.watchAllActive().first;
    expect(active, hasLength(1));
    expect(active.single.id, 'rule-1');
    expect(active.single.note, 'Gym');

    final due = await repository.listDue(DateTime(2026, 2, 10));
    expect(due, hasLength(1));
    expect(due.single.id, 'rule-1');

    await repository.update(
      rule.copyWith(
        nextRunAt: DateTime(2026, 3, 10),
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );

    final notDue = await repository.listDue(DateTime(2026, 2, 28));
    expect(notDue, isEmpty);

    await repository.softDelete('rule-1');
    final afterDelete = await repository.watchAllActive().first;
    expect(afterDelete, isEmpty);
  });
}

Future<void> _insertDependencies(
  AppDatabase db, {
  required DateTime now,
}) async {
  await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          id: 'acc-1',
          name: 'Main',
          type: 'bank',
          initialBalance: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: 'cat-1',
          name: 'General Expense',
          type: 'expense',
          icon: 'tag',
          color: '#607D8B',
          createdAt: now,
          updatedAt: now,
        ),
      );
}
