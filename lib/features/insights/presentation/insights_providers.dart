import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/insights/domain/category_analytics_calculator.dart';
import 'package:finora/features/insights/domain/goal_progress_calculator.dart';
import 'package:finora/features/insights/domain/net_worth_calculator.dart';
import 'package:finora/features/predictions/domain/budget_variance_calculator.dart';
import 'package:finora/features/transactions/presentation/transactions_providers.dart';

class InsightsOverviewData {
  const InsightsOverviewData({
    required this.income,
    required this.expense,
  });

  final double income;
  final double expense;

  double get net => income - expense;
}

final netWorthCalculatorProvider = Provider<NetWorthCalculator>((ref) {
  return const NetWorthCalculator();
});

final goalProgressCalculatorProvider = Provider<GoalProgressCalculator>((ref) {
  return const GoalProgressCalculator();
});

final insightsOverviewProvider = Provider<AsyncValue<InsightsOverviewData>>((ref) {
  final totalsAsync = ref.watch(monthlyTotalsProvider);
  return totalsAsync.whenData(
    (totals) => InsightsOverviewData(
      income: totals.incomeTotal,
      expense: totals.expenseTotal,
    ),
  );
});

final insightsCategoryBreakdownProvider =
    Provider<AsyncValue<List<CategoryAnalyticsItem>>>((ref) {
  final categoriesAsync = ref.watch(expenseCategoriesProvider);
  final transactionsAsync = ref.watch(transactionsByMonthProvider);

  if (categoriesAsync.isLoading || transactionsAsync.isLoading) {
    return const AsyncLoading();
  }
  if (categoriesAsync.hasError) {
    return AsyncError(
      categoriesAsync.error!,
      categoriesAsync.stackTrace ?? StackTrace.current,
    );
  }
  if (transactionsAsync.hasError) {
    return AsyncError(
      transactionsAsync.error!,
      transactionsAsync.stackTrace ?? StackTrace.current,
    );
  }

  final calculator = ref.watch(categoryAnalyticsCalculatorProvider);
  final items = calculator.calculate(
    categories: categoriesAsync.value!,
    transactions: transactionsAsync.value!,
    type: CategoryType.expense,
  );
  return AsyncData(items);
});

final insightsNetWorthProvider = Provider<AsyncValue<NetWorthResult>>((ref) {
  final accountsAsync = ref.watch(activeAccountsProvider);
  final transactionsAsync = ref.watch(transactionsByMonthProvider);

  if (accountsAsync.isLoading || transactionsAsync.isLoading) {
    return const AsyncLoading();
  }
  if (accountsAsync.hasError) {
    return AsyncError(
      accountsAsync.error!,
      accountsAsync.stackTrace ?? StackTrace.current,
    );
  }
  if (transactionsAsync.hasError) {
    return AsyncError(
      transactionsAsync.error!,
      transactionsAsync.stackTrace ?? StackTrace.current,
    );
  }

  final calculator = ref.watch(netWorthCalculatorProvider);
  final result = calculator.calculate(
    accounts: accountsAsync.value!,
    transactions: transactionsAsync.value!,
  );
  return AsyncData(result);
});

final insightsGoalProgressProvider =
    Provider<AsyncValue<List<GoalProgressItem>>>((ref) {
  final goalsAsync = ref.watch(goalsProvider);

  if (goalsAsync.isLoading) {
    return const AsyncLoading();
  }
  if (goalsAsync.hasError) {
    return AsyncError(
      goalsAsync.error!,
      goalsAsync.stackTrace ?? StackTrace.current,
    );
  }

  final calculator = ref.watch(goalProgressCalculatorProvider);
  final items = calculator.calculate(goals: goalsAsync.value!);
  return AsyncData(items);
});

final insightsBudgetVarianceProvider =
    Provider<AsyncValue<BudgetVarianceResult>>((ref) {
  return ref.watch(budgetVarianceProvider);
});
