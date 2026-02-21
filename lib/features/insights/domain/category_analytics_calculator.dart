import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/transactions/domain/transaction.dart';

class CategoryAnalyticsItem {
  const CategoryAnalyticsItem({
    required this.categoryId,
    required this.categoryName,
    required this.type,
    required this.total,
  });

  final String categoryId;
  final String categoryName;
  final CategoryType type;
  final double total;
}

class CategoryAnalyticsCalculator {
  const CategoryAnalyticsCalculator();

  List<CategoryAnalyticsItem> calculate({
    required List<Category> categories,
    required List<Transaction> transactions,
    CategoryType? type,
  }) {
    final categoryById = <String, Category>{};
    for (final category in categories) {
      if (category.isDeleted) {
        continue;
      }
      categoryById[category.id] = category;
    }

    final totals = <String, double>{};
    final typeByCategoryId = <String, CategoryType>{};
    for (final transaction in transactions) {
      if (transaction.isDeleted ||
          transaction.type == TransactionType.transfer) {
        continue;
      }
      final category = categoryById[transaction.categoryId];
      final transactionType = transaction.type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense;
      final effectiveType = category?.type ?? transactionType;
      if (type != null && effectiveType != type) {
        continue;
      }
      totals[transaction.categoryId] =
          (totals[transaction.categoryId] ?? 0) + transaction.amount;
      typeByCategoryId[transaction.categoryId] = effectiveType;
    }

    final items = totals.entries.map((entry) {
      final category = categoryById[entry.key];
      return CategoryAnalyticsItem(
        categoryId: entry.key,
        categoryName: category?.name ?? entry.key,
        type: category?.type ??
            typeByCategoryId[entry.key] ??
            CategoryType.expense,
        total: entry.value,
      );
    }).toList(growable: false);

    items.sort((a, b) => b.total.compareTo(a.total));
    return items;
  }
}
