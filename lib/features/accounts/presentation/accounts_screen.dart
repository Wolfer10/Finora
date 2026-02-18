import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/utils/money_formatter.dart';
import 'package:finora/core/widgets/finora_card.dart';
import 'package:finora/features/accounts/domain/account.dart';
import 'package:finora/features/transactions/presentation/transactions_providers.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(activeAccountsProvider);
    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return const FinoraCard(
            child: Text('No accounts yet. Use Add Account to create one.'),
          );
        }
        return FinoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accounts', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final account in accounts) ...[
                _AccountRow(account: account),
                const SizedBox(height: AppSpacing.md),
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
            Text('Loading accounts...'),
          ],
        ),
      ),
      error: (error, _) => FinoraCard(
        child: Text(
          'Failed to load accounts: $error',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
        ),
      ),
    );
  }
}

class AddAccountDialog extends ConsumerStatefulWidget {
  const AddAccountDialog({super.key});

  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();
  AccountType _type = AccountType.bank;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Account'),
      content: SizedBox(
        width: 420,
        child: _AccountForm(
          formKey: _formKey,
          nameController: _nameController,
          balanceController: _balanceController,
          type: _type,
          onTypeChanged: (value) {
            if (value != null) {
              setState(() => _type = value);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final initialBalance = double.tryParse(_balanceController.text.trim());
    if (initialBalance == null) {
      return;
    }
    await ref.read(accountNotifierProvider.notifier).createAccount(
          name: _nameController.text,
          type: _type,
          initialBalance: initialBalance,
        );
    final state = ref.read(accountNotifierProvider);
    if (state.hasError) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create account: ${state.error}')),
      );
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _EditAccountDialog extends ConsumerStatefulWidget {
  const _EditAccountDialog({required this.account});

  final Account account;

  @override
  ConsumerState<_EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends ConsumerState<_EditAccountDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  final _formKey = GlobalKey<FormState>();
  late AccountType _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _balanceController = TextEditingController(
      text: widget.account.initialBalance.toStringAsFixed(2),
    );
    _type = widget.account.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Account'),
      content: SizedBox(
        width: 420,
        child: _AccountForm(
          formKey: _formKey,
          nameController: _nameController,
          balanceController: _balanceController,
          type: _type,
          onTypeChanged: (value) {
            if (value != null) {
              setState(() => _type = value);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final initialBalance = double.tryParse(_balanceController.text.trim());
    if (initialBalance == null) {
      return;
    }
    await ref.read(accountNotifierProvider.notifier).updateAccount(
          account: widget.account,
          name: _nameController.text,
          type: _type,
          initialBalance: initialBalance,
        );
    final state = ref.read(accountNotifierProvider);
    if (state.hasError) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update account: ${state.error}')),
      );
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _AccountRow extends ConsumerWidget {
  const _AccountRow({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Type: ${account.type.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          MoneyFormatter.format(account.initialBalance),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Edit account',
          onPressed: () async {
            await showDialog<void>(
              context: context,
              builder: (_) => _EditAccountDialog(account: account),
            );
          },
          icon: const Icon(Icons.edit_outlined),
          iconSize: AppSizes.iconSm,
        ),
        IconButton(
          tooltip: 'Delete account',
          onPressed: () => _confirmDelete(context, ref, account.id),
          icon: const Icon(Icons.delete_outline),
          iconSize: AppSizes.iconSm,
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String accountId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will remove the account from active lists.'),
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
      ),
    );
    if (shouldDelete != true) {
      return;
    }
    await ref.read(accountNotifierProvider.notifier).deleteAccount(accountId);
    final state = ref.read(accountNotifierProvider);
    if (state.hasError && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: ${state.error}')),
      );
    }
  }
}

class _AccountForm extends StatelessWidget {
  const _AccountForm({
    required this.formKey,
    required this.nameController,
    required this.balanceController,
    required this.type,
    required this.onTypeChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController balanceController;
  final AccountType type;
  final ValueChanged<AccountType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Account name'),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<AccountType>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: AccountType.cash, child: Text('Cash')),
              DropdownMenuItem(value: AccountType.bank, child: Text('Bank')),
              DropdownMenuItem(value: AccountType.savings, child: Text('Savings')),
              DropdownMenuItem(
                value: AccountType.investment,
                child: Text('Investment'),
              ),
              DropdownMenuItem(
                value: AccountType.credit,
                child: Text('Credit'),
              ),
            ],
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Initial balance'),
            validator: (value) {
              if (double.tryParse(value ?? '') == null) {
                return 'Enter a valid amount';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
