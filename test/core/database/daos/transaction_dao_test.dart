import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/transaction_dao.dart';

void main() {
  late AppDatabase db;
  late TransactionDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = TransactionDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('watchRecent returns newest first with createdAt tie-break and excludes soft-deleted rows', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-same-date-old-created',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 10,
        date: DateTime(2026, 2, 2),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-same-date-new-created',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 20,
        date: DateTime(2026, 2, 2),
        createdAt: now.add(const Duration(minutes: 1)),
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-new-deleted',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 30,
        date: DateTime(2026, 2, 3),
        createdAt: now,
        updatedAt: now,
        isDeleted: const Value(true),
      ),
    );

    final rows = await dao.watchRecent(2).first;
    expect(rows.map((row) => row.id), ['tx-same-date-new-created', 'tx-same-date-old-created']);
  });

  test('watchRecent supports accountId filter', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: 'acc-2',
            name: 'Second',
            type: 'cash',
            initialBalance: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-acc-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 10,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-acc-2',
        accountId: 'acc-2',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 20,
        date: DateTime(2026, 2, 11),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final rows = await dao.watchRecent(10, accountId: 'acc-1').first;
    expect(rows.map((row) => row.id), ['tx-acc-1']);
  });

  test('watchByMonth includes start boundary and excludes next month boundary', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-start',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 100,
        date: DateTime(2026, 2, 1, 0, 0, 0),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-inside',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 200,
        date: DateTime(2026, 2, 28, 23, 59, 59),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-end-excluded',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 300,
        date: DateTime(2026, 3, 1, 0, 0, 0),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-deleted',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 400,
        date: DateTime(2026, 2, 15),
        createdAt: now,
        updatedAt: now,
        isDeleted: const Value(true),
      ),
    );

    final rows = await dao.watchByMonth(2026, 2).first;
    expect(rows.map((row) => row.id), ['tx-inside', 'tx-start']);
  });

  test('watchByMonth supports account/category/type filters', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: 'acc-2',
            name: 'Second',
            type: 'cash',
            initialBalance: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: 'cat-2',
            name: 'Second Cat',
            type: 'expense',
            icon: 'tag',
            color: '#654321',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-keep',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 10,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-other-account',
        accountId: 'acc-2',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 10,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-other-category',
        accountId: 'acc-1',
        categoryId: 'cat-2',
        type: 'expense',
        amount: 10,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-other-type',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 10,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final rows = await dao
        .watchByMonth(
          2026,
          2,
          accountId: 'acc-1',
          categoryId: 'cat-1',
          type: 'expense',
        )
        .first;

    expect(rows.map((row) => row.id), ['tx-keep']);
  });

  test('watchTransfersByMonth returns only transfer rows for requested month', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-transfer-keep',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'transfer',
        amount: 99,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-income-skip',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 99,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-transfer-next-month',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'transfer',
        amount: 88,
        date: DateTime(2026, 3, 1),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final rows = await dao.watchTransfersByMonth(2026, 2).first;
    expect(rows.map((row) => row.id), ['tx-transfer-keep']);
  });

  test('softDeleteById marks transaction deleted and updates timestamp', () async {
    final createdAt = DateTime(2026, 2, 13, 9, 0);
    final updatedAt = DateTime(2026, 2, 13, 10, 0);
    await _insertDependencies(db, now: createdAt);

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 42,
        date: DateTime(2026, 2, 12),
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    await dao.softDeleteById('tx-1', updatedAt);

    final row = await (db.select(db.transactions)..where((tbl) => tbl.id.equals('tx-1')))
        .getSingle();
    expect(row.isDeleted, isTrue);
    expect(row.updatedAt, updatedAt);
  });

  test('monthlyTotals excludes transfers and supports type filter', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-income',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 100,
        date: DateTime(2026, 2, 2),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-expense',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 30,
        date: DateTime(2026, 2, 3),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-transfer',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'transfer',
        amount: 999,
        date: DateTime(2026, 2, 4),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final totals = await dao.monthlyTotals(2026, 2);
    expect(totals.incomeTotal, 100);
    expect(totals.expenseTotal, 30);
    expect(totals.net, 70);

    final transferOnly = await dao.monthlyTotals(2026, 2, type: 'transfer');
    expect(transferOnly.incomeTotal, 0);
    expect(transferOnly.expenseTotal, 0);
  });

  test('categoryTotals returns expense totals sorted descending', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: 'cat-2',
            name: 'Other',
            type: 'expense',
            icon: 'tag',
            color: '#abcdef',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 80,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-2',
        accountId: 'acc-1',
        categoryId: 'cat-2',
        type: 'expense',
        amount: 30,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final rows = await dao.categoryTotals(2026, 2).first;
    expect(rows.map((it) => it.categoryId), ['cat-1', 'cat-2']);
    expect(rows.map((it) => it.totalExpense), [80, 30]);
  });

  test('categoryTotals supports accountId filter', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: 'acc-2',
            name: 'Second',
            type: 'cash',
            initialBalance: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-acc-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 80,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-acc-2',
        accountId: 'acc-2',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 30,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final rows = await dao.categoryTotals(2026, 2, accountId: 'acc-1').first;
    expect(rows.map((it) => it.categoryId), ['cat-1']);
    expect(rows.map((it) => it.totalExpense), [80]);
  });

  test('monthlyTotalByType sums by month and type and excludes soft-deleted rows', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-income-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 1200.5,
        date: DateTime(2026, 2, 2),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-income-2',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 99.5,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-income-deleted',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 500,
        date: DateTime(2026, 2, 20),
        createdAt: now,
        updatedAt: now,
        isDeleted: const Value(true),
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-expense',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 25,
        date: DateTime(2026, 2, 3),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-next-month',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 777,
        date: DateTime(2026, 3, 1),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final incomeTotal = await dao.monthlyTotalByType(2026, 2, type: 'income');
    final expenseTotal = await dao.monthlyTotalByType(2026, 2, type: 'expense');
    final transferTotal = await dao.monthlyTotalByType(2026, 2, type: 'transfer');

    expect(incomeTotal, 1300);
    expect(expenseTotal, 25);
    expect(transferTotal, 0);
  });

  test('monthlyTotalsRange groups by month, sorts ascending and ignores transfers', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-jan-income',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 50,
        date: DateTime(2026, 1, 15),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-feb-expense',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'expense',
        amount: 20,
        date: DateTime(2026, 2, 15),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-feb-transfer',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'transfer',
        amount: 999,
        date: DateTime(2026, 2, 20),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-mar-income-excluded',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 200,
        date: DateTime(2026, 3, 1),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final points = await dao.monthlyTotalsRange(2026, 1, 2026, 3).first;

    expect(points.map((it) => '${it.year}-${it.month}'), ['2026-1', '2026-2']);
    expect(points[0].incomeTotal, 50);
    expect(points[0].expenseTotal, 0);
    expect(points[1].incomeTotal, 0);
    expect(points[1].expenseTotal, 20);
  });

  test('account-specific wrappers apply account filter for month and range', () async {
    final now = DateTime(2026, 2, 13, 9, 0);
    await _insertDependencies(db, now: now);

    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: 'acc-2',
            name: 'Second',
            type: 'cash',
            initialBalance: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-acc-1-income',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'income',
        amount: 100,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      TransactionsCompanion.insert(
        id: 'tx-acc-2-income',
        accountId: 'acc-2',
        categoryId: 'cat-1',
        type: 'income',
        amount: 500,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final byMonthRows = await dao
        .watchAccountTransactionsByMonth(2026, 2, accountId: 'acc-1')
        .first;
    expect(byMonthRows.map((it) => it.id), ['tx-acc-1-income']);

    final monthTotals =
        await dao.monthlyTotalsForAccount(2026, 2, accountId: 'acc-1');
    expect(monthTotals.incomeTotal, 100);
    expect(monthTotals.expenseTotal, 0);

    final rangePoints = await dao
        .monthlyTotalsRangeForAccount(2026, 2, 2026, 3, accountId: 'acc-1')
        .first;
    expect(rangePoints, hasLength(1));
    expect(rangePoints.single.incomeTotal, 100);
    expect(rangePoints.single.expenseTotal, 0);
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
          initialBalance: 1000,
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: 'cat-1',
          name: 'General',
          type: 'expense',
          icon: 'tag',
          color: '#123456',
          createdAt: now,
          updatedAt: now,
        ),
      );
}
