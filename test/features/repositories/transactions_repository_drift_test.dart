import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/account_dao.dart';
import 'package:finora/core/database/daos/category_dao.dart';
import 'package:finora/core/database/daos/transaction_dao.dart';
import 'package:finora/core/errors/repository_error.dart';
import 'package:finora/features/accounts/data/account_repository_drift.dart';
import 'package:finora/features/accounts/domain/account.dart' as domain;
import 'package:finora/features/categories/data/category_repository_drift.dart';
import 'package:finora/features/categories/domain/category.dart' as domain;
import 'package:finora/features/transactions/data/transaction_repository_drift.dart';
import 'package:finora/features/transactions/domain/transaction.dart' as domain;

void main() {
  late AppDatabase db;
  late AccountRepositoryDrift accountRepository;
  late CategoryRepositoryDrift categoryRepository;
  late TransactionRepositoryDrift transactionRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepository = AccountRepositoryDrift(AccountDao(db));
    categoryRepository = CategoryRepositoryDrift(CategoryDao(db));
    transactionRepository = TransactionRepositoryDrift(TransactionDao(db));
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  test('watchRecent/watchByMonth/totals ignore transfers and soft-deleted', () async {
    final now = DateTime(2026, 2, 12, 9, 0);
    const accountId = 'acc-1';
    const incomeCategoryId = 'cat-income-1';
    const expenseCategoryId = 'cat-expense-1';

    await accountRepository.create(
      domain.Account(
        id: accountId,
        name: 'Bank',
        type: domain.AccountType.bank,
        initialBalance: 1000,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    await categoryRepository.create(
      domain.Category(
        id: incomeCategoryId,
        name: 'Salary',
        type: domain.CategoryType.income,
        icon: 'attach_money',
        color: '#2E7D32',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    await categoryRepository.create(
      domain.Category(
        id: expenseCategoryId,
        name: 'Food',
        type:  domain.CategoryType.expense,
        icon: 'restaurant',
        color: '#EF6C00',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    await transactionRepository.create(
      domain.Transaction(
        id: 'tx-income',
        accountId: accountId,
        categoryId: incomeCategoryId,
        type:  domain.TransactionType.income,
        amount: 2000,
        date: DateTime(2026, 2, 3),
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    await transactionRepository.create(
      domain.Transaction(
        id: 'tx-expense',
        accountId: accountId,
        categoryId: expenseCategoryId,
        type:  domain.TransactionType.expense,
        amount: 350.25,
        date: DateTime(2026, 2, 10),
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    await transactionRepository.create(
      domain.Transaction(
        id: 'tx-transfer',
        accountId: accountId,
        categoryId: expenseCategoryId,
        type:  domain.TransactionType.transfer,
        amount: 999,
        date: DateTime(2026, 2, 11),
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        transferGroupId: 'trg-1',
      ),
    );

    await transactionRepository.create(
      domain.Transaction(
        id: 'tx-next-month',
        accountId: accountId,
        categoryId: expenseCategoryId,
        type:  domain.TransactionType.expense,
        amount: 50,
        date: DateTime(2026, 3, 1),
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    final recent = await transactionRepository.watchRecent(2).first;
    expect(recent, hasLength(2));
    expect(recent.first.id, 'tx-next-month');
    expect(recent.last.id, 'tx-transfer');

    final february = await transactionRepository.watchByMonth(2026, 2).first;
    expect(
      february.map((tx) => tx.id),
      containsAll(['tx-income', 'tx-expense', 'tx-transfer']),
    );
    expect(february.map((tx) => tx.id), isNot(contains('tx-next-month')));

    final incomeTotal = await transactionRepository.monthlyIncomeTotal(2026, 2);
    final expenseTotal =
        await transactionRepository.monthlyExpenseTotal(2026, 2);
    expect(incomeTotal, 2000);
    expect(expenseTotal, 350.25);

    await transactionRepository.softDelete('tx-expense');
    final expenseAfterDelete =
        await transactionRepository.monthlyExpenseTotal(2026, 2);
    expect(expenseAfterDelete, 0);
  });

  test('monthlyTotals wraps DAO failure as RepositoryError', () async {
    final failingRepository = TransactionRepositoryDrift(
      _ThrowingTransactionDaoForTotals(db),
    );

    await expectLater(
      failingRepository.monthlyTotals(2026, 2),
      throwsA(isA<RepositoryError>()),
    );
  });

  test('watchRecent wraps stream failure as RepositoryError', () async {
    final failingRepository = TransactionRepositoryDrift(
      _ThrowingTransactionDaoForRecent(db),
    );

    await expectLater(
      failingRepository.watchRecent(5).first,
      throwsA(isA<RepositoryError>()),
    );
  });

  test('listByTransferGroup and softDeleteByTransferGroup affect linked records', () async {
    final now = DateTime(2026, 2, 18, 9, 0);
    await accountRepository.create(
      domain.Account(
        id: 'acc-a',
        name: 'A',
        type: domain.AccountType.bank,
        initialBalance: 0,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );
    await accountRepository.create(
      domain.Account(
        id: 'acc-b',
        name: 'B',
        type: domain.AccountType.bank,
        initialBalance: 0,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );
    await categoryRepository.create(
      domain.Category(
        id: 'cat-transfer',
        name: 'Transfer',
        type: domain.CategoryType.expense,
        icon: 'swap_horiz',
        color: '#6B7280',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );
    await transactionRepository.create(
      domain.Transaction(
        id: 'tx-1',
        accountId: 'acc-a',
        categoryId: 'cat-transfer',
        type: domain.TransactionType.transfer,
        amount: 100,
        date: DateTime(2026, 2, 18),
        transferGroupId: 'grp-1',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );
    await transactionRepository.create(
      domain.Transaction(
        id: 'tx-2',
        accountId: 'acc-b',
        categoryId: 'cat-transfer',
        type: domain.TransactionType.transfer,
        amount: 100,
        date: DateTime(2026, 2, 18),
        transferGroupId: 'grp-1',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    final linkedBefore = await transactionRepository.listByTransferGroup('grp-1');
    expect(linkedBefore, hasLength(2));

    await transactionRepository.softDeleteByTransferGroup('grp-1');

    final linkedAfter = await transactionRepository.listByTransferGroup('grp-1');
    expect(linkedAfter, isEmpty);
  });
}

class _ThrowingTransactionDaoForTotals extends TransactionDao {
  _ThrowingTransactionDaoForTotals(super.db);

  @override
  Future<MonthlyTotalsRow> monthlyTotals(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    String? type,
  }) {
    throw StateError('totals failed');
  }
}

class _ThrowingTransactionDaoForRecent extends TransactionDao {
  _ThrowingTransactionDaoForRecent(super.db);

  @override
  Stream<List<Transaction>> watchRecent(int limit, {String? accountId}) {
    return Stream<List<Transaction>>.error(StateError('watch recent failed'));
  }
}
