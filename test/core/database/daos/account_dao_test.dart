import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/account_dao.dart';

void main() {
  late AppDatabase db;
  late AccountDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = AccountDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('watchAll returns only non-deleted accounts when activeOnly=true', () async {
    final now = DateTime(2026, 2, 13, 10, 0);

    await dao.upsert(
      AccountsCompanion.insert(
        id: 'acc-z',
        name: 'Zebra',
        type: 'cash',
        initialBalance: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      AccountsCompanion.insert(
        id: 'acc-a',
        name: 'Alpha',
        type: 'bank',
        initialBalance: 2,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      AccountsCompanion.insert(
        id: 'acc-deleted',
        name: 'Hidden',
        type: 'cash',
        initialBalance: 0,
        createdAt: now,
        updatedAt: now,
        isDeleted: const Value(true),
      ),
    );

    final rows = await dao.watchAll(activeOnly: true).first;
    expect(rows.map((row) => row.id), ['acc-a', 'acc-z']);
  });

  test('watchAll includes deleted accounts when activeOnly=false', () async {
    final now = DateTime(2026, 2, 13, 10, 0);

    await dao.upsert(
      AccountsCompanion.insert(
        id: 'acc-a',
        name: 'Alpha',
        type: 'bank',
        initialBalance: 2,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      AccountsCompanion.insert(
        id: 'acc-deleted',
        name: 'Deleted',
        type: 'cash',
        initialBalance: 0,
        createdAt: now,
        updatedAt: now,
        isDeleted: const Value(true),
      ),
    );

    final rows = await dao.watchAll(activeOnly: false).first;
    expect(rows.map((row) => row.id), ['acc-a', 'acc-deleted']);
  });

  test('watchBalances computes initial + income - expense and ignores transfer', () async {
    final now = DateTime(2026, 2, 13, 10, 0);

    await dao.upsert(
      AccountsCompanion.insert(
        id: 'acc-1',
        name: 'Main',
        type: 'bank',
        initialBalance: 100,
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

    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            id: 'tx-income',
            accountId: 'acc-1',
            categoryId: 'cat-1',
            type: 'income',
            amount: 50,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            id: 'tx-expense',
            accountId: 'acc-1',
            categoryId: 'cat-1',
            type: 'expense',
            amount: 20,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            id: 'tx-transfer',
            accountId: 'acc-1',
            categoryId: 'cat-1',
            type: 'transfer',
            amount: 999,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        );

    final balances = await dao.watchBalances().first;
    expect(balances.single.accountId, 'acc-1');
    expect(balances.single.balance, 130);

    final balance = await dao.watchAccountBalance('acc-1').first;
    expect(balance, 130);
  });

  test('softDeleteById marks row deleted and updates timestamp', () async {
    final createdAt = DateTime(2026, 2, 13, 10, 0);
    final updatedAt = DateTime(2026, 2, 13, 11, 0);

    await dao.upsert(
      AccountsCompanion.insert(
        id: 'acc-1',
        name: 'Main',
        type: 'bank',
        initialBalance: 100,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    await dao.softDeleteById('acc-1', updatedAt);

    final row = await (db.select(db.accounts)..where((tbl) => tbl.id.equals('acc-1')))
        .getSingle();
    expect(row.isDeleted, isTrue);
    expect(row.updatedAt, updatedAt);
  });
}
