import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/predictions/domain/budget_variance_calculator.dart';
import 'package:finora/features/predictions/domain/monthly_prediction.dart';
import 'package:finora/features/transactions/domain/transaction.dart';

void main() {
  test('calculates per-category and total variance', () {
    const calculator = BudgetVarianceCalculator();
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
        id: 'cat-transport',
        name: 'Transport',
        type: CategoryType.expense,
        icon: 'directions_car',
        color: '#1565C0',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    ];

    final predictions = [
      MonthlyPrediction(
        id: 'pred-1',
        year: 2026,
        month: 2,
        categoryId: 'cat-food',
        predictedAmount: 400,
        note: null,
        createdAt: now,
        updatedAt: now,
      ),
      MonthlyPrediction(
        id: 'pred-2',
        year: 2026,
        month: 2,
        categoryId: 'cat-transport',
        predictedAmount: 150,
        note: null,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final transactions = [
      Transaction(
        id: 'tx-1',
        accountId: 'acc-main',
        categoryId: 'cat-food',
        type: TransactionType.expense,
        amount: 450,
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
        categoryId: 'cat-transport',
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
    ];

    final result = calculator.calculate(
      categories: categories,
      predictions: predictions,
      transactions: transactions,
    );

    expect(result.items, hasLength(2));
    expect(result.totalPredicted, 550);
    expect(result.totalActual, 550);
    expect(result.totalVariance, 0);

    final food = result.items.firstWhere((item) => item.categoryId == 'cat-food');
    expect(food.predicted, 400);
    expect(food.actual, 450);
    expect(food.variance, 50);
  });
}
