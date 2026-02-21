import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/insights/domain/category_analytics_calculator.dart';
import 'package:finora/features/transactions/domain/transaction.dart';

void main() {
  test('calculates monthly per-category totals and ignores transfers', () {
    const calculator = CategoryAnalyticsCalculator();
    final now = DateTime(2026, 2, 1);

    final categories = [
      Category(
        id: 'cat-food',
        name: 'Food',
        type: CategoryType.expense,
        icon: 'restaurant',
        color: '#EF6C00',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Category(
        id: 'cat-salary',
        name: 'Salary',
        type: CategoryType.income,
        icon: 'payments',
        color: '#2E7D32',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Category(
        id: 'cat-archived',
        name: 'Archived',
        type: CategoryType.expense,
        icon: 'archive',
        color: '#616161',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: true,
      ),
    ];

    final transactions = [
      Transaction(
        id: 'tx-1',
        accountId: 'acc-main',
        categoryId: 'cat-food',
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
        id: 'tx-2',
        accountId: 'acc-main',
        categoryId: 'cat-food',
        type: TransactionType.expense,
        amount: 70,
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
        categoryId: 'cat-salary',
        type: TransactionType.income,
        amount: 2000,
        date: now,
        note: null,
        transferGroupId: null,
        recurringRuleId: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Transaction(
        id: 'tx-4',
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
        id: 'tx-5',
        accountId: 'acc-main',
        categoryId: 'cat-unknown',
        type: TransactionType.expense,
        amount: 30,
        date: now,
        note: null,
        transferGroupId: null,
        recurringRuleId: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    ];

    final expenseItems = calculator.calculate(
      categories: categories,
      transactions: transactions,
      type: CategoryType.expense,
    );
    final incomeItems = calculator.calculate(
      categories: categories,
      transactions: transactions,
      type: CategoryType.income,
    );

    final food =
        expenseItems.firstWhere((item) => item.categoryId == 'cat-food');
    final unknown = expenseItems.firstWhere(
      (item) => item.categoryId == 'cat-unknown',
    );
    final salary = incomeItems.firstWhere(
      (item) => item.categoryId == 'cat-salary',
    );

    expect(food.total, 120);
    expect(unknown.total, 30);
    expect(salary.total, 2000);
    expect(expenseItems.any((item) => item.categoryId == 'cat-transfer-system'),
        false);
  });
}
