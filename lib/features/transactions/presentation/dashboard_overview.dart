import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/utils/color_utils.dart';
import 'package:finora/core/utils/money_formatter.dart';
import 'package:finora/core/widgets/finora_card.dart';
import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/transactions/domain/transaction.dart'
    as tx_domain;
import 'package:finora/features/transactions/domain/transaction_repository.dart'
    as tx_repo;
import 'package:finora/features/transactions/presentation/transactions_providers.dart';
import 'package:finora/features/transactions/presentation/transactions_screen.dart';

class DashboardOverview extends ConsumerWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(monthlyTotalsProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Column(
      children: [
        FinoraCard(
          child: totalsAsync.when(
            data: (totals) => _MonthlyTotalsView(totals: totals),
            loading: () => const _PanelLoading(label: 'Loading monthly totals...'),
            error: (error, _) => _PanelError(
              message: 'Failed to load monthly totals: $error',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FinoraCard(
          child: recentAsync.when(
            data: (List<tx_domain.Transaction> transactions) =>
                _RecentTransactionsView(
                  transactions: transactions,
                ),
            loading: () =>
                const _PanelLoading(label: 'Loading recent transactions...'),
            error: (error, _) => _PanelError(
              message: 'Failed to load recent transactions: $error',
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthlyTotalsView extends StatelessWidget {
  const _MonthlyTotalsView({required this.totals});

  final tx_repo.MonthlyTotals totals;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Monthly Summary', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        _MetricRow(
          label: 'Income',
          value: MoneyFormatter.format(totals.incomeTotal),
          valueColor: AppColors.income,
        ),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(
          label: 'Expense',
          value: MoneyFormatter.format(totals.expenseTotal),
          valueColor: AppColors.expense,
        ),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(
          label: 'Net',
          value: MoneyFormatter.format(totals.net),
          valueColor: totals.net >= 0 ? AppColors.income : AppColors.expense,
        ),
      ],
    );
  }
}

class _RecentTransactionsView extends ConsumerWidget {
  const _RecentTransactionsView({required this.transactions});

  final List<tx_domain.Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final categories = ref.watch(activeCategoriesProvider).valueOrNull ?? const <Category>[];
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    if (transactions.isEmpty) {
      return Text(
        'No transactions yet. Add your first transaction from the Transactions tab.',
        style: textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Transactions', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        for (final tx in transactions) ...[
          _RecentTransactionRow(
            transaction: tx,
            category: categoryById[tx.categoryId],
            onEdit: () async {
              await showDialog<void>(
                context: context,
                builder: (dialogContext) {
                  return EditExpenseDialog(transaction: tx);
                },
              );
            },
            onDelete: () => _confirmDelete(context, ref, tx),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    tx_domain.Transaction transaction,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('This will remove the transaction from active lists.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await ref
        .read(transactionNotifierProvider.notifier)
        .deleteTransactionByEntity(transaction);
    final saveState = ref.read(transactionNotifierProvider);
    if (saveState.hasError && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: ${saveState.error}')),
      );
    }
  }

}

class _RecentTransactionRow extends StatelessWidget {
  const _RecentTransactionRow({
    required this.transaction,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final tx_domain.Transaction transaction;
  final Category? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = parseHexColor(
      category?.color,
      _typeColor(transaction.type),
    );
    final backgroundColor = Color.alphaBlend(
      categoryColor.withOpacity(0.10),
      colorScheme.surface,
    );
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: categoryColor.withOpacity(0.45)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: AppSizes.iconLg,
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note ?? category?.name ?? transaction.categoryId,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  category?.name ?? transaction.categoryId,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if ((transaction.recurringRuleId ?? '').isNotEmpty) ...[
            Tooltip(
              message: 'Recurring transaction',
              child: Icon(
                Icons.repeat,
                size: AppSizes.iconSm,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            MoneyFormatter.format(transaction.amount),
            style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _typeColor(transaction.type),
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Edit transaction',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          iconSize: AppSizes.iconSm,
        ),
          IconButton(
            tooltip: 'Delete transaction',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            iconSize: AppSizes.iconSm,
          ),
      ]
        ),
    );
  }

  Color _typeColor(tx_domain.TransactionType type) {
    switch (type) {
      case tx_domain.TransactionType.income:
        return AppColors.income;
      case tx_domain.TransactionType.expense:
        return AppColors.expense;
      case tx_domain.TransactionType.transfer:
        return AppColors.transfer;
    }
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: textTheme.bodyLarge),
        ),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _PanelLoading extends StatelessWidget {
  const _PanelLoading({required this.label});

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

class _PanelError extends StatelessWidget {
  const _PanelError({required this.message});

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
