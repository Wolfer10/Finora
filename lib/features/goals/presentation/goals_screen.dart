import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/utils/money_formatter.dart';
import 'package:finora/core/widgets/finora_card.dart';
import 'package:finora/features/goals/domain/goal.dart';
import 'package:finora/features/transactions/presentation/transactions_providers.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return const FinoraCard(
            child: Text('No goals yet. Use Add Goal to create your first goal.'),
          );
        }

        return FinoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Goals', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final goal in goals) ...[
                _GoalRow(goal: goal),
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
            Text('Loading goals...'),
          ],
        ),
      ),
      error: (error, _) => FinoraCard(
        child: Text(
          'Failed to load goals: $error',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
        ),
      ),
    );
  }
}

class AddGoalDialog extends ConsumerStatefulWidget {
  const AddGoalDialog({super.key});

  @override
  ConsumerState<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  GoalPriority _priority = GoalPriority.medium;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Goal'),
      content: SizedBox(
        width: 420,
        child: _GoalForm(
          formKey: _formKey,
          nameController: _nameController,
          targetController: _targetController,
          priority: _priority,
          onPriorityChanged: (value) {
            if (value != null) {
              setState(() => _priority = value);
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
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    final target = double.tryParse(_targetController.text.trim());
    if (target == null || target <= 0) {
      return;
    }
    await ref.read(goalNotifierProvider.notifier).createGoal(
          name: _nameController.text.trim(),
          targetAmount: target,
          priority: _priority,
        );
    final saveState = ref.read(goalNotifierProvider);
    if (saveState.hasError) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create goal: ${saveState.error}')),
      );
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _EditGoalDialog extends ConsumerStatefulWidget {
  const _EditGoalDialog({required this.goal});

  final Goal goal;

  @override
  ConsumerState<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends ConsumerState<_EditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late GoalPriority _priority;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
    _targetController = TextEditingController(
      text: widget.goal.targetAmount.toStringAsFixed(2),
    );
    _priority = widget.goal.priority;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Goal'),
      content: SizedBox(
        width: 420,
        child: _GoalForm(
          formKey: _formKey,
          nameController: _nameController,
          targetController: _targetController,
          priority: _priority,
          onPriorityChanged: (value) {
            if (value != null) {
              setState(() => _priority = value);
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
          onPressed: _submit,
          child: const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    final target = double.tryParse(_targetController.text.trim());
    if (target == null || target <= 0) {
      return;
    }
    await ref.read(goalNotifierProvider.notifier).updateGoal(
          goal: widget.goal,
          name: _nameController.text.trim(),
          targetAmount: target,
          priority: _priority,
        );
    final saveState = ref.read(goalNotifierProvider);
    if (saveState.hasError) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update goal: ${saveState.error}')),
      );
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _AddContributionDialog extends ConsumerStatefulWidget {
  const _AddContributionDialog({required this.goalId});

  final String goalId;

  @override
  ConsumerState<_AddContributionDialog> createState() =>
      _AddContributionDialogState();
}

class _AddContributionDialogState extends ConsumerState<_AddContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Contribution'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
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
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
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

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      return;
    }

    await ref.read(goalNotifierProvider.notifier).addContribution(
          goalId: widget.goalId,
          amount: amount,
          note: _noteController.text,
        );
    final saveState = ref.read(goalNotifierProvider);
    if (saveState.hasError) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add contribution: ${saveState.error}')),
      );
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _GoalRow extends ConsumerWidget {
  const _GoalRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = goal.targetAmount == 0
        ? 0.0
        : (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Add contribution',
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) => _AddContributionDialog(
                    goalId: goal.id,
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              iconSize: AppSizes.iconSm,
            ),
            IconButton(
              tooltip: 'Edit goal',
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) => _EditGoalDialog(goal: goal),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              iconSize: AppSizes.iconSm,
            ),
            IconButton(
              tooltip: 'Delete goal',
              onPressed: () => _confirmDelete(context, ref, goal.id),
              icon: const Icon(Icons.delete_outline),
              iconSize: AppSizes.iconSm,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${MoneyFormatter.format(goal.savedAmount)} / ${MoneyFormatter.format(goal.targetAmount)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Priority: ${goal.priority.name} • ${goal.completed ? 'Completed' : 'In progress'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (goal.completedAt != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Completed at: ${MaterialLocalizations.of(context).formatMediumDate(goal.completedAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String goalId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('This will remove the goal from active lists.'),
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
    await ref.read(goalNotifierProvider.notifier).deleteGoal(goalId);
    final deleteState = ref.read(goalNotifierProvider);
    if (deleteState.hasError && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete goal: ${deleteState.error}')),
      );
    }
  }
}

class _GoalForm extends StatelessWidget {
  const _GoalForm({
    required this.formKey,
    required this.nameController,
    required this.targetController,
    required this.priority,
    required this.onPriorityChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController targetController;
  final GoalPriority priority;
  final ValueChanged<GoalPriority?> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Goal name'),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target amount'),
            validator: (value) {
              final parsed = double.tryParse(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Enter a valid amount > 0';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<GoalPriority>(
            initialValue: priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(
                value: GoalPriority.high,
                child: Text('High'),
              ),
              DropdownMenuItem(
                value: GoalPriority.medium,
                child: Text('Medium'),
              ),
              DropdownMenuItem(
                value: GoalPriority.low,
                child: Text('Low'),
              ),
            ],
            onChanged: onPriorityChanged,
          ),
        ],
      ),
    );
  }
}
