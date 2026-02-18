import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/utils/color_utils.dart';
import 'package:finora/core/utils/money_formatter.dart';
import 'package:finora/core/widgets/finora_card.dart';
import 'package:finora/features/accounts/domain/account.dart';
import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/transactions/domain/add_expense_transaction_use_case.dart';
import 'package:finora/features/transactions/domain/transaction.dart';
import 'package:finora/features/transactions/domain/update_expense_transaction_use_case.dart';
import 'package:finora/features/transactions/presentation/transactions_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsByMonthProvider);
    final categories = ref.watch(activeCategoriesProvider).valueOrNull ?? const <Category>[];
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const FinoraCard(
            child: Text('No transactions in this month. Use Add Expense to create one.'),
          );
        }

        return FinoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final transaction in transactions) ...[
                _TransactionRow(
                  transaction: transaction,
                  category: categoryById[transaction.categoryId],
                  onEdit: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return EditExpenseDialog(transaction: transaction);
                      },
                    );
                  },
                  onDelete: () => _confirmDelete(context, ref, transaction),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
      loading: () => const FinoraCard(
        child: Row(
          children: [
            SizedBox.square(
              dimension: AppSizes.iconMd,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.md),
            Text('Loading transactions...'),
          ],
        ),
      ),
      error: (error, _) => FinoraCard(
        child: Text(
          'Failed to load transactions: $error',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
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
        .deleteTransaction(transaction.id);
    final saveState = ref.read(transactionNotifierProvider);
    if (saveState.hasError && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: ${saveState.error}')),
      );
    }
  }
}

class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _accountId;
  String? _categoryId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return AlertDialog(
      title: const Text('Add Expense'),
      content: SizedBox(
        width: 420,
        child: accountsAsync.when(
          data: (accounts) => categoriesAsync.when(
            data: (categories) => _buildForm(accounts, categories),
            loading: () => const _DialogLoading(),
            error: (error, _) => _DialogError(message: 'Categories error: $error'),
          ),
          loading: () => const _DialogLoading(),
          error: (error, _) => _DialogError(message: 'Accounts error: $error'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildForm(List<Account> accounts, List<Category> categories) {
    if (accounts.isEmpty || categories.isEmpty) {
      return const Text(
        'At least one account and expense category is required before adding an expense.',
      );
    }

    _accountId ??= accounts.first.id;
    _categoryId ??= categories.first.id;

    return _ExpenseTransactionForm(
      formKey: _formKey,
      accounts: accounts,
      categories: categories,
      amountController: _amountController,
      noteController: _noteController,
      accountId: _accountId,
      categoryId: _categoryId,
      onAccountChanged: (value) => setState(() => _accountId = value),
      onCategoryChanged: (value) => setState(() => _categoryId = value),
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final accountId = _accountId;
    final categoryId = _categoryId;
    final amount = double.tryParse(_amountController.text.trim());
    if (accountId == null || categoryId == null || amount == null || amount <= 0) {
      return;
    }

    final selectedMonth = ref.read(selectedMonthProvider);
    final monthDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final input = AddExpenseTransactionInput(
      accountId: accountId,
      categoryId: categoryId,
      amount: amount,
      date: monthDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ref.read(transactionNotifierProvider.notifier).addExpense(input);
    final saveState = ref.read(transactionNotifierProvider);
    if (saveState.hasError) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save transaction: ${saveState.error}')),
      );
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class EditExpenseDialog extends ConsumerStatefulWidget {
  const EditExpenseDialog({
    required this.transaction,
    super.key,
  });

  final Transaction transaction;

  @override
  ConsumerState<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends ConsumerState<EditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _accountId;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(
      text: widget.transaction.note ?? '',
    );
    _accountId = widget.transaction.accountId;
    _categoryId = widget.transaction.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return AlertDialog(
      title: const Text('Update Expense'),
      content: SizedBox(
        width: 420,
        child: accountsAsync.when(
          data: (accounts) => categoriesAsync.when(
            data: (categories) => _buildForm(accounts, categories),
            loading: () => const _DialogLoading(),
            error: (error, _) => _DialogError(message: 'Categories error: $error'),
          ),
          loading: () => const _DialogLoading(),
          error: (error, _) => _DialogError(message: 'Accounts error: $error'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Update'),
        ),
      ],
    );
  }

  Widget _buildForm(List<Account> accounts, List<Category> categories) {
    if (accounts.isEmpty || categories.isEmpty) {
      return const Text(
        'At least one account and expense category is required before updating an expense.',
      );
    }

    _accountId ??= accounts.first.id;
    _categoryId ??= categories.first.id;

    return _ExpenseTransactionForm(
      formKey: _formKey,
      accounts: accounts,
      categories: categories,
      amountController: _amountController,
      noteController: _noteController,
      accountId: _accountId,
      categoryId: _categoryId,
      onAccountChanged: (value) => setState(() => _accountId = value),
      onCategoryChanged: (value) => setState(() => _categoryId = value),
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final accountId = _accountId;
    final categoryId = _categoryId;
    final amount = double.tryParse(_amountController.text.trim());
    if (accountId == null || categoryId == null || amount == null || amount <= 0) {
      return;
    }

    final input = UpdateExpenseTransactionInput(
      transactionId: widget.transaction.id,
      accountId: accountId,
      categoryId: categoryId,
      amount: amount,
      date: widget.transaction.date,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ref
        .read(transactionNotifierProvider.notifier)
        .updateExpense(widget.transaction, input);
    final saveState = ref.read(transactionNotifierProvider);
    if (saveState.hasError) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update transaction: ${saveState.error}')),
      );
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _ExpenseTransactionForm extends StatelessWidget {
  const _ExpenseTransactionForm({
    required this.formKey,
    required this.accounts,
    required this.categories,
    required this.amountController,
    required this.noteController,
    required this.accountId,
    required this.categoryId,
    required this.onAccountChanged,
    required this.onCategoryChanged,
  });

  final GlobalKey<FormState> formKey;
  final List<Account> accounts;
  final List<Category> categories;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final String? accountId;
  final String? categoryId;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: accountId,
            decoration: const InputDecoration(labelText: 'Account'),
            items: [
              for (final account in accounts)
                DropdownMenuItem(value: account.id, child: Text(account.name)),
            ],
            onChanged: onAccountChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: categoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final category in categories)
                DropdownMenuItem(value: category.id, child: Text(category.name)),
            ],
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
            validator: (value) {
              final parsed = double.tryParse(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Enter a valid amount > 0';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Transaction transaction;
  final Category? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(
      transaction.date,
    );
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  '${category?.name ?? transaction.categoryId} | $dateLabel',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            MoneyFormatter.format(transaction.amount),
            style: textTheme.bodyLarge?.copyWith(
              color: _typeColor(transaction.type),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Edit transaction',
            onPressed:
                transaction.type == TransactionType.expense ? onEdit : null,
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

  Color _typeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }
}

class _DialogLoading extends StatelessWidget {
  const _DialogLoading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox.square(
          dimension: AppSizes.iconMd,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(child: Text('Loading form data...')),
      ],
    );
  }
}

class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});

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
