import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/insights/domain/monthly_summary_calculator.dart';
import 'package:finora/features/transactions/domain/transaction.dart';

void main() {
  test('calculates income, expense and net while ignoring transfers', () {
    const calculator = MonthlySummaryCalculator();
    final now = DateTime(2026, 2, 1);

    final transactions = [
      Transaction(
        id: 'tx-1',
        accountId: 'acc-main',
        categoryId: 'cat-salary',
        type: TransactionType.income,
        amount: 1200,
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
        accountId: 'acc-main',
        categoryId: 'cat-food',
        type: TransactionType.expense,
        amount: 250,
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
        accountId: 'acc-main',
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
        accountId: 'acc-main',
        categoryId: 'cat-food',
        type: TransactionType.expense,
        amount: 100,
        date: now,
        note: null,
        transferGroupId: null,
        recurringRuleId: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: true,
      ),
    ];

    final result = calculator.calculate(transactions: transactions);

    expect(result.incomeTotal, 1200);
    expect(result.expenseTotal, 250);
    expect(result.net, 950);
  });
}
