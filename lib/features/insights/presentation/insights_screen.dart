import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/utils/color_utils.dart';
import 'package:finora/core/utils/money_formatter.dart';
import 'package:finora/core/widgets/finora_card.dart';
import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/insights/domain/goal_progress_calculator.dart';
import 'package:finora/features/insights/domain/net_worth_calculator.dart';
import 'package:finora/features/insights/presentation/insights_providers.dart';
import 'package:finora/features/predictions/domain/budget_variance_calculator.dart';
import 'package:finora/features/transactions/presentation/transactions_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 5,
      child: FinoraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Net Worth'),
                Tab(text: 'Categories'),
                Tab(text: 'Goals'),
                Tab(text: 'Budget'),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 520,
              child: TabBarView(
                children: [
                  _InsightsOverviewTab(),
                  _InsightsNetWorthTab(),
                  _InsightsCategoriesTab(),
                  _InsightsGoalsTab(),
                  _InsightsBudgetTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsOverviewTab extends ConsumerWidget {
  const _InsightsOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(insightsOverviewProvider);
    return overviewAsync.when(
      data: (overview) => ListView(
        children: [
          _MetricRow(
            label: 'Income',
            value: MoneyFormatter.format(overview.income),
            color: AppColors.income,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(
            label: 'Expense',
            value: MoneyFormatter.format(overview.expense),
            color: AppColors.expense,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(
            label: 'Net',
            value: MoneyFormatter.format(overview.net),
            color: overview.net >= 0 ? AppColors.income : AppColors.expense,
          ),
        ],
      ),
      loading: () => const _TabLoading(label: 'Loading overview...'),
      error: (error, _) => _TabError(message: 'Overview failed: $error'),
    );
  }
}

class _InsightsNetWorthTab extends ConsumerWidget {
  const _InsightsNetWorthTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorthAsync = ref.watch(insightsNetWorthProvider);
    return netWorthAsync.when(
      data: (result) {
        if (result.accounts.isEmpty) {
          return const Text('No accounts found for net worth view.');
        }

        return ListView(
          children: [
            _MetricRow(
              label: 'Assets',
              value: MoneyFormatter.format(result.assets),
              color: AppColors.income,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetricRow(
              label: 'Liabilities',
              value: MoneyFormatter.format(result.liabilities),
              color: AppColors.expense,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetricRow(
              label: 'Net Worth',
              value: MoneyFormatter.format(result.netWorth),
              color: result.netWorth >= 0 ? AppColors.income : AppColors.expense,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final account in result.accounts) ...[
              _NetWorthAccountRow(account: account),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
      loading: () => const _TabLoading(label: 'Loading net worth...'),
      error: (error, _) => _TabError(message: 'Net worth failed: $error'),
    );
  }
}

class _InsightsCategoriesTab extends ConsumerWidget {
  const _InsightsCategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryItemsAsync = ref.watch(insightsCategoryBreakdownProvider);
    return categoryItemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Text('No category expenses in this month.');
        }

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = items[index];
            return _MetricRow(
              label: item.categoryName,
              value: MoneyFormatter.format(item.total),
              color: AppColors.expense,
            );
          },
        );
      },
      loading: () => const _TabLoading(label: 'Loading categories...'),
      error: (error, _) => _TabError(message: 'Categories failed: $error'),
    );
  }
}

class _InsightsGoalsTab extends ConsumerWidget {
  const _InsightsGoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalProgressAsync = ref.watch(insightsGoalProgressProvider);
    return goalProgressAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Text('No goals yet. Add goals to track progress here.');
        }

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final item = items[index];
            return _GoalProgressRow(item: item);
          },
        );
      },
      loading: () => const _TabLoading(label: 'Loading goals progress...'),
      error: (error, _) => _TabError(message: 'Goals progress failed: $error'),
    );
  }
}

class _InsightsBudgetTab extends ConsumerWidget {
  const _InsightsBudgetTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final varianceAsync = ref.watch(insightsBudgetVarianceProvider);
    final categories = ref.watch(expenseCategoriesProvider).valueOrNull ?? const <Category>[];
    final colorByCategoryId = <String, Color>{
      for (final category in categories)
        category.id: parseHexColor(
          category.color,
          Theme.of(context).colorScheme.outlineVariant,
        ),
    };
    return varianceAsync.when(
      data: (variance) {
        if (variance.items.isEmpty) {
          return const Text('No budget prediction data for this month yet.');
        }

        return ListView(
          children: [
            _MetricRow(
              label: 'Total Predicted',
              value: MoneyFormatter.format(variance.totalPredicted),
              color: AppColors.transfer,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetricRow(
              label: 'Total Actual',
              value: MoneyFormatter.format(variance.totalActual),
              color: AppColors.expense,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetricRow(
              label: 'Total Variance',
              value: MoneyFormatter.format(variance.totalVariance),
              color: variance.totalVariance <= 0
                  ? AppColors.income
                  : AppColors.expense,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in variance.items) ...[
              _BudgetCategoryRow(
                item: item,
                color: colorByCategoryId[item.categoryId] ?? AppColors.transfer,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
      loading: () => const _TabLoading(label: 'Loading budget variance...'),
      error: (error, _) => _TabError(message: 'Budget variance failed: $error'),
    );
  }
}

class _NetWorthAccountRow extends StatelessWidget {
  const _NetWorthAccountRow({required this.account});

  final AccountNetWorthItem account;

  @override
  Widget build(BuildContext context) {
    return _MetricRow(
      label: account.accountName,
      value: MoneyFormatter.format(account.balance),
      color: account.balance >= 0 ? AppColors.income : AppColors.expense,
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  const _GoalProgressRow({required this.item});

  final GoalProgressItem item;

  @override
  Widget build(BuildContext context) {
    final percentage = (item.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricRow(
          label: item.goalName,
          value: MoneyFormatter.format(item.savedAmount),
          color: item.completed ? AppColors.income : AppColors.transfer,
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(value: item.progress),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Target ${MoneyFormatter.format(item.targetAmount)} | '
          'Remaining ${MoneyFormatter.format(item.remainingAmount)} | '
          '$percentage%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _BudgetCategoryRow extends StatelessWidget {
  const _BudgetCategoryRow({
    required this.item,
    required this.color,
  });

  final BudgetVarianceItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = Color.alphaBlend(
      color.withOpacity(0.10),
      colorScheme.surface,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: AppSizes.iconLg,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.categoryName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Predicted ${MoneyFormatter.format(item.predicted)} | '
                  'Actual ${MoneyFormatter.format(item.actual)} | '
                  'Variance ${MoneyFormatter.format(item.variance)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _TabLoading extends StatelessWidget {
  const _TabLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox.square(
          dimension: AppSizes.iconMd,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _TabError extends StatelessWidget {
  const _TabError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.error,
          ),
    );
  }
}
