import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/predictions/domain/monthly_prediction.dart';
import 'package:finora/features/transactions/domain/transaction.dart';

class BudgetVarianceItem {
  const BudgetVarianceItem({
    required this.categoryId,
    required this.categoryName,
    required this.predicted,
    required this.actual,
  });

  final String categoryId;
  final String categoryName;
  final double predicted;
  final double actual;

  double get variance => actual - predicted;
}

class BudgetVarianceResult {
  const BudgetVarianceResult({
    required this.items,
    required this.totalPredicted,
    required this.totalActual,
  });

  final List<BudgetVarianceItem> items;
  final double totalPredicted;
  final double totalActual;

  double get totalVariance => totalActual - totalPredicted;
}

class BudgetVarianceCalculator {
  const BudgetVarianceCalculator();

  BudgetVarianceResult calculate({
    required List<Category> categories,
    required List<MonthlyPrediction> predictions,
    required List<Transaction> transactions,
  }) {
    final categoryNameById = <String, String>{};
    for (final category in categories) {
      if (category.type == CategoryType.expense && !category.isDeleted) {
        categoryNameById[category.id] = category.name;
      }
    }

    final predictedByCategory = <String, double>{};
    for (final prediction in predictions) {
      predictedByCategory[prediction.categoryId] =
          (predictedByCategory[prediction.categoryId] ?? 0) +
          prediction.predictedAmount;
      categoryNameById.putIfAbsent(
        prediction.categoryId,
        () => prediction.categoryId,
      );
    }

    final actualByCategory = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense || transaction.isDeleted) {
        continue;
      }
      actualByCategory[transaction.categoryId] =
          (actualByCategory[transaction.categoryId] ?? 0) + transaction.amount;
      categoryNameById.putIfAbsent(
        transaction.categoryId,
        () => transaction.categoryId,
      );
    }

    final categoryIds = <String>{
      ...categoryNameById.keys,
      ...predictedByCategory.keys,
      ...actualByCategory.keys,
    };

    final items = categoryIds
        .map(
          (categoryId) => BudgetVarianceItem(
            categoryId: categoryId,
            categoryName: categoryNameById[categoryId] ?? categoryId,
            predicted: predictedByCategory[categoryId] ?? 0,
            actual: actualByCategory[categoryId] ?? 0,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.actual.compareTo(a.actual));

    var totalPredicted = 0.0;
    var totalActual = 0.0;
    for (final item in items) {
      totalPredicted += item.predicted;
      totalActual += item.actual;
    }

    return BudgetVarianceResult(
      items: items,
      totalPredicted: totalPredicted,
      totalActual: totalActual,
    );
  }
}
