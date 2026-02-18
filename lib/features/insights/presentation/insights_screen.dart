import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/utils/money_formatter.dart';
import 'package:finora/core/widgets/finora_card.dart';
import 'package:finora/features/transactions/presentation/transactions_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 3,
      child: FinoraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Categories'),
                Tab(text: 'Budget'),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 420,
              child: TabBarView(
                children: [
                  _InsightsOverviewTab(),
                  _InsightsCategoriesTab(),
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
    final totalsAsync = ref.watch(monthlyTotalsProvider);
    return totalsAsync.when(
      data: (totals) => ListView(
        children: [
          _MetricRow(
            label: 'Income',
            value: MoneyFormatter.format(totals.incomeTotal),
            color: AppColors.income,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(
            label: 'Expense',
            value: MoneyFormatter.format(totals.expenseTotal),
            color: AppColors.expense,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(
            label: 'Net',
            value: MoneyFormatter.format(totals.net),
            color: totals.net >= 0 ? AppColors.income : AppColors.expense,
          ),
        ],
      ),
      loading: () => const _TabLoading(label: 'Loading overview...'),
      error: (error, _) => _TabError(message: 'Overview failed: $error'),
    );
  }
}

class _InsightsCategoriesTab extends ConsumerWidget {
  const _InsightsCategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final totalsAsync = ref.watch(categoryExpenseTotalsProvider);

    if (categoriesAsync.isLoading || totalsAsync.isLoading) {
      return const _TabLoading(label: 'Loading categories...');
    }
    if (categoriesAsync.hasError) {
      return _TabError(message: 'Categories failed: ${categoriesAsync.error}');
    }
    if (totalsAsync.hasError) {
      return _TabError(message: 'Category totals failed: ${totalsAsync.error}');
    }

    final nameById = <String, String>{
      for (final category in categoriesAsync.value!) category.id: category.name,
    };
    final items = totalsAsync.value!.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    if (items.isEmpty) {
      return const Text('No category expenses in this month.');
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        final label = nameById[item.key] ?? item.key;
        return _MetricRow(
          label: label,
          value: MoneyFormatter.format(item.value),
          color: AppColors.expense,
        );
      },
    );
  }
}

class _InsightsBudgetTab extends ConsumerWidget {
  const _InsightsBudgetTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final varianceAsync = ref.watch(budgetVarianceProvider);
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
