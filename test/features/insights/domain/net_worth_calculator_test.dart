import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/accounts/domain/account.dart';
import 'package:finora/features/insights/domain/net_worth_calculator.dart';
import 'package:finora/features/transactions/domain/transaction.dart';

void main() {
  test('computes net worth from account balances and handles negatives', () {
    const calculator = NetWorthCalculator();
    final now = DateTime(2026, 2, 1);

    final accounts = [
      Account(
        id: 'acc-checking',
        name: 'Checking',
        type: AccountType.bank,
        initialBalance: 1000,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Account(
        id: 'acc-credit',
        name: 'Credit card',
        type: AccountType.credit,
        initialBalance: -200,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Account(
        id: 'acc-deleted',
        name: 'Deleted',
        type: AccountType.cash,
        initialBalance: 500,
        createdAt: now,
        updatedAt: now,
        isDeleted: true,
      ),
    ];

    final transactions = [
      Transaction(
        id: 'tx-1',
        accountId: 'acc-checking',
        categoryId: 'cat-salary',
        type: TransactionType.income,
        amount: 500,
        date: now,
        note: null,
        transferGroupId: null,
        recurringRuleId: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Transaction(
        id: 'tx-2',
        accountId: 'acc-checking',
        categoryId: 'cat-food',
        type: TransactionType.expense,
        amount: 100,
        date: now,
        note: null,
        transferGroupId: null,
        recurringRuleId: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Transaction(
        id: 'tx-3',
        accountId: 'acc-checking',
        categoryId: 'cat-transfer-system',
        type: TransactionType.transfer,
        amount: 300,
        date: now,
        note: null,
        transferGroupId: 'txg-1',
        recurringRuleId: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Transaction(
        id: 'tx-4',
        accountId: 'acc-credit',
        categoryId: 'cat-shopping',
        type: TransactionType.expense,
        amount: 50,
        date: now,
        note: null,
        transferGroupId: null,
        recurringRuleId: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Transaction(
        id: 'tx-5',
        accountId: 'acc-credit',
        categoryId: 'cat-refund',
        type: TransactionType.income,
        amount: 100,
        date: now,
        note: null,
        transferGroupId: null,
        recurringRuleId: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: true,
      ),
      Transaction(
        id: 'tx-6',
        accountId: 'acc-deleted',
        categoryId: 'cat-salary',
        type: TransactionType.income,
        amount: 999,
        date: now,
        note: null,
        transferGroupId: null,
        recurringRuleId: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    ];

    final result =
        calculator.calculate(accounts: accounts, transactions: transactions);

    expect(result.accounts, hasLength(2));
    expect(result.assets, 1400);
    expect(result.liabilities, 250);
    expect(result.netWorth, 1150);

    final credit = result.accounts.firstWhere(
      (item) => item.accountId == 'acc-credit',
    );
    expect(credit.balance, -250);
  });
}
