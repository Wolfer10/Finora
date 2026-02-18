import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/utils/color_utils.dart';
import 'package:finora/core/utils/money_formatter.dart';
import 'package:finora/core/widgets/finora_card.dart';
import 'package:finora/features/accounts/domain/account.dart';
import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/transactions/domain/recurring_rule.dart';
import 'package:finora/features/transactions/domain/transaction.dart';
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
            child: Text(
              'No transactions in this month. Use Add Transaction to create one.',
            ),
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
        .deleteTransactionByEntity(transaction);
    final saveState = ref.read(transactionNotifierProvider);
    if (saveState.hasError && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: ${saveState.error}')),
      );
    }
  }
}

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  bool _createRecurringRule = false;
  RecurrenceUnit _recurrenceUnit = RecurrenceUnit.monthly;
  final _recurrenceIntervalController = TextEditingController(text: '1');
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _recurrenceIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return AlertDialog(
      title: const Text('Add Transaction'),
      content: SizedBox(
        width: 420,
        child: accountsAsync.when(
          data: (accounts) => categoriesAsync.when(
            data: (categories) => _buildForm(context, accounts, categories),
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

  Widget _buildForm(
    BuildContext context,
    List<Account> accounts,
    List<Category> categories,
  ) {
    if (accounts.isEmpty) {
      return const Text(
        'At least one account is required before adding a transaction.',
      );
    }
    final filteredCategories = categories
        .where((category) => category.type.name == _type.name)
        .toList(growable: false);
    if (_type == TransactionType.transfer && accounts.length < 2) {
      return const Text(
        'At least two accounts are required for a transfer transaction.',
      );
    }
    if (_type != TransactionType.transfer && filteredCategories.isEmpty) {
      return const Text(
        'Create a matching category first for this transaction type.',
      );
    }

    _accountId ??= accounts.first.id;
    if (_type == TransactionType.transfer) {
      _toAccountId ??= accounts.length > 1 ? accounts[1].id : null;
      _categoryId = null;
    } else {
      _categoryId ??= filteredCategories.first.id;
      _toAccountId = null;
    }

    return _TransactionForm(
      formKey: _formKey,
      type: _type,
      accounts: accounts,
      categories: filteredCategories,
      amountController: _amountController,
      noteController: _noteController,
      accountId: _accountId,
      toAccountId: _toAccountId,
      categoryId: _categoryId,
      createRecurringRule: _createRecurringRule,
      recurrenceUnit: _recurrenceUnit,
      recurrenceIntervalController: _recurrenceIntervalController,
      onTypeChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() {
          _type = value;
          _categoryId = null;
          _toAccountId = null;
        });
      },
      onAccountChanged: (value) => setState(() => _accountId = value),
      onToAccountChanged: (value) => setState(() => _toAccountId = value),
      onCategoryChanged: (value) => setState(() => _categoryId = value),
      onCreateRecurringChanged: (value) {
        setState(() {
          _createRecurringRule = value;
        });
      },
      onRecurrenceUnitChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() {
          _recurrenceUnit = value;
        });
      },
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final accountId = _accountId;
    final toAccountId = _toAccountId;
    final categoryId = _categoryId;
    final amount = double.tryParse(_amountController.text.trim());
    final recurrenceInterval =
        int.tryParse(_recurrenceIntervalController.text.trim()) ?? 0;
    if (accountId == null || amount == null || amount <= 0) {
      return;
    }
    if (_createRecurringRule && recurrenceInterval <= 0) {
      return;
    }
    if (_type == TransactionType.transfer) {
      if (toAccountId == null || toAccountId == accountId) {
        return;
      }
    } else if (categoryId == null) {
      return;
    }

    final selectedMonth = ref.read(selectedMonthProvider);
    final monthDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
    await ref.read(transactionNotifierProvider.notifier).addTransaction(
          type: _type,
          accountId: accountId,
          toAccountId: toAccountId,
          categoryId: categoryId,
          amount: amount,
          date: monthDate,
          note: _noteController.text,
          createRecurringRule: _createRecurringRule,
          recurrenceUnit: _recurrenceUnit,
          recurrenceInterval: recurrenceInterval <= 0 ? 1 : recurrenceInterval,
        );
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

class AddExpenseDialog extends AddTransactionDialog {
  const AddExpenseDialog({super.key});
}

class EditTransactionDialog extends ConsumerStatefulWidget {
  const EditTransactionDialog({
    required this.transaction,
    super.key,
  });

  final Transaction transaction;

  @override
  ConsumerState<EditTransactionDialog> createState() =>
      _EditTransactionDialogState();
}

class _EditTransactionDialogState extends ConsumerState<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;
  bool _loadingTransferAccounts = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(
      text: widget.transaction.note ?? '',
    );
    _type = widget.transaction.type;
    _accountId = widget.transaction.accountId;
    _categoryId = widget.transaction.categoryId;
    if (_type == TransactionType.transfer &&
        (widget.transaction.transferGroupId?.isNotEmpty ?? false)) {
      _loadingTransferAccounts = true;
      _loadTransferCounterpart();
    }
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
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return AlertDialog(
      title: const Text('Update Transaction'),
      content: SizedBox(
        width: 420,
        child: accountsAsync.when(
          data: (accounts) => categoriesAsync.when(
            data: (categories) => _buildForm(context, accounts, categories),
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

  Widget _buildForm(
    BuildContext context,
    List<Account> accounts,
    List<Category> categories,
  ) {
    if (accounts.isEmpty) {
      return const Text(
        'At least one account is required before updating a transaction.',
      );
    }
    if (_loadingTransferAccounts) {
      return const _DialogLoading();
    }
    final filteredCategories = categories
        .where((category) => category.type.name == _type.name)
        .toList(growable: false);
    if (_type == TransactionType.transfer && accounts.length < 2) {
      return const Text(
        'At least two accounts are required for a transfer transaction.',
      );
    }
    if (_type != TransactionType.transfer && filteredCategories.isEmpty) {
      return const Text(
        'Create a matching category first for this transaction type.',
      );
    }

    _accountId ??= accounts.first.id;
    if (_type == TransactionType.transfer) {
      _toAccountId ??= accounts.length > 1 ? accounts[1].id : null;
      _categoryId = null;
    } else {
      _toAccountId = null;
      if (_categoryId == null ||
          !filteredCategories.any((category) => category.id == _categoryId)) {
        _categoryId = filteredCategories.first.id;
      }
    }

    return _TransactionForm(
      formKey: _formKey,
      type: _type,
      accounts: accounts,
      categories: filteredCategories,
      amountController: _amountController,
      noteController: _noteController,
      accountId: _accountId,
      toAccountId: _toAccountId,
      categoryId: _categoryId,
      showRecurringControls: false,
      onTypeChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() {
          _type = value;
          _categoryId = null;
          _toAccountId = null;
        });
      },
      onAccountChanged: (value) => setState(() => _accountId = value),
      onToAccountChanged: (value) => setState(() => _toAccountId = value),
      onCategoryChanged: (value) => setState(() => _categoryId = value),
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final accountId = _accountId;
    final toAccountId = _toAccountId;
    final categoryId = _categoryId;
    final amount = double.tryParse(_amountController.text.trim());
    if (accountId == null || amount == null || amount <= 0) {
      return;
    }
    if (_type == TransactionType.transfer) {
      if (toAccountId == null || toAccountId == accountId) {
        return;
      }
    } else if (categoryId == null) {
      return;
    }

    await ref
        .read(transactionNotifierProvider.notifier)
        .updateTransaction(
          original: widget.transaction,
          type: _type,
          accountId: accountId,
          toAccountId: toAccountId,
          categoryId: categoryId,
          amount: amount,
          date: widget.transaction.date,
          note: _noteController.text,
        );
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

  Future<void> _loadTransferCounterpart() async {
    final transferGroupId = widget.transaction.transferGroupId;
    if (transferGroupId == null || transferGroupId.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingTransferAccounts = false;
        });
      }
      return;
    }
    final linked = await ref
        .read(transactionRepositoryProvider)
        .listByTransferGroup(transferGroupId);
    Transaction? counterpart;
    for (final tx in linked) {
      if (tx.id != widget.transaction.id) {
        counterpart = tx;
        break;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _toAccountId = counterpart?.accountId;
      _loadingTransferAccounts = false;
    });
  }
}

class EditExpenseDialog extends EditTransactionDialog {
  const EditExpenseDialog({
    required super.transaction,
    super.key,
  });
}

class _TransactionForm extends StatelessWidget {
  const _TransactionForm({
    required this.formKey,
    required this.type,
    required this.accounts,
    required this.categories,
    required this.amountController,
    required this.noteController,
    required this.accountId,
    required this.toAccountId,
    required this.categoryId,
    this.createRecurringRule = false,
    this.recurrenceUnit = RecurrenceUnit.monthly,
    this.recurrenceIntervalController,
    this.showRecurringControls = true,
    required this.onTypeChanged,
    required this.onAccountChanged,
    required this.onToAccountChanged,
    required this.onCategoryChanged,
    this.onCreateRecurringChanged,
    this.onRecurrenceUnitChanged,
  });

  final GlobalKey<FormState> formKey;
  final TransactionType type;
  final List<Account> accounts;
  final List<Category> categories;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final bool createRecurringRule;
  final RecurrenceUnit recurrenceUnit;
  final TextEditingController? recurrenceIntervalController;
  final bool showRecurringControls;
  final ValueChanged<TransactionType?> onTypeChanged;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<String?> onToAccountChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool>? onCreateRecurringChanged;
  final ValueChanged<RecurrenceUnit?>? onRecurrenceUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<TransactionType>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(
                value: TransactionType.expense,
                child: Text('Expense'),
              ),
              DropdownMenuItem(
                value: TransactionType.income,
                child: Text('Income'),
              ),
              DropdownMenuItem(
                value: TransactionType.transfer,
                child: Text('Transfer'),
              ),
            ],
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: accountId,
            decoration: InputDecoration(
              labelText: type == TransactionType.transfer
                  ? 'From account'
                  : 'Account',
            ),
            items: [
              for (final account in accounts)
                DropdownMenuItem(value: account.id, child: Text(account.name)),
            ],
            onChanged: onAccountChanged,
          ),
          if (type == TransactionType.transfer) ...[
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: toAccountId,
              decoration: const InputDecoration(labelText: 'To account'),
              items: [
                for (final account in accounts)
                  if (account.id != accountId)
                    DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ),
              ],
              onChanged: onToAccountChanged,
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'Select destination account';
                }
                if (value == accountId) {
                  return 'Destination must be different';
                }
                return null;
              },
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in categories)
                  DropdownMenuItem(value: category.id, child: Text(category.name)),
              ],
              onChanged: onCategoryChanged,
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'Category is required';
                }
                return null;
              },
            ),
          ],
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
          if (showRecurringControls) ...[
            const SizedBox(height: AppSpacing.md),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Create recurring rule'),
              value: createRecurringRule,
              onChanged: onCreateRecurringChanged,
            ),
            if (createRecurringRule) ...[
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<RecurrenceUnit>(
                initialValue: recurrenceUnit,
                decoration: const InputDecoration(labelText: 'Recurrence'),
                items: const [
                  DropdownMenuItem(
                    value: RecurrenceUnit.daily,
                    child: Text('Daily'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceUnit.weekly,
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceUnit.monthly,
                    child: Text('Monthly'),
                  ),
                ],
                onChanged: onRecurrenceUnitChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: recurrenceIntervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Repeat every (interval)',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter an interval > 0';
                  }
                  return null;
                },
              ),
            ],
          ],
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
              color: _typeColor(transaction.type),
              fontWeight: FontWeight.w600,
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
        ],
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
