import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/utils/color_utils.dart';
import 'package:finora/core/widgets/finora_card.dart';
import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/transactions/presentation/transactions_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const FinoraCard(
            child: Text('No categories yet. Use Add Category to create one.'),
          );
        }
        return FinoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Categories', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final category in categories) ...[
                _CategoryRow(category: category),
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
            Text('Loading categories...'),
          ],
        ),
      ),
      error: (error, _) => FinoraCard(
        child: Text(
          'Failed to load categories: $error',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
        ),
      ),
    );
  }
}

class AddCategoryDialog extends ConsumerStatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController(text: 'category');
  final _colorController = TextEditingController(text: '#607D8B');
  final _formKey = GlobalKey<FormState>();
  CategoryType _type = CategoryType.expense;

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: SizedBox(
        width: 420,
        child: _CategoryForm(
          formKey: _formKey,
          nameController: _nameController,
          iconController: _iconController,
          colorController: _colorController,
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
    await ref.read(categoryNotifierProvider.notifier).createCategory(
          name: _nameController.text,
          type: _type,
          icon: _iconController.text,
          color: _colorController.text,
        );
    final state = ref.read(categoryNotifierProvider);
    if (state.hasError) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create category: ${state.error}')),
      );
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _EditCategoryDialog extends ConsumerStatefulWidget {
  const _EditCategoryDialog({required this.category});

  final Category category;

  @override
  ConsumerState<_EditCategoryDialog> createState() =>
      _EditCategoryDialogState();
}

class _EditCategoryDialogState extends ConsumerState<_EditCategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _iconController;
  late final TextEditingController _colorController;
  final _formKey = GlobalKey<FormState>();
  late CategoryType _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _iconController = TextEditingController(text: widget.category.icon);
    _colorController = TextEditingController(text: widget.category.color);
    _type = widget.category.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Category'),
      content: SizedBox(
        width: 420,
        child: _CategoryForm(
          formKey: _formKey,
          nameController: _nameController,
          iconController: _iconController,
          colorController: _colorController,
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
    await ref.read(categoryNotifierProvider.notifier).updateCategory(
          category: widget.category,
          name: _nameController.text,
          type: _type,
          icon: _iconController.text,
          color: _colorController.text,
        );
    final state = ref.read(categoryNotifierProvider);
    if (state.hasError) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update category: ${state.error}')),
      );
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = parseHexColor(
      category.color,
      colorScheme.outlineVariant,
    );
    final backgroundColor = Color.alphaBlend(
      categoryColor.withOpacity(0.10),
      colorScheme.surface,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: categoryColor.withOpacity(0.45), width: 1.5),
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
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Type: ${category.type.name} | Icon: ${category.icon} | Color: ${category.color}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit category',
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (_) => _EditCategoryDialog(category: category),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            iconSize: AppSizes.iconSm,
          ),
          IconButton(
            tooltip: 'Delete category',
            onPressed: () => _confirmDelete(context, ref, category.id),
            icon: const Icon(Icons.delete_outline),
            iconSize: AppSizes.iconSm,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('This will remove the category from active lists.'),
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
    await ref.read(categoryNotifierProvider.notifier).deleteCategory(categoryId);
    final state = ref.read(categoryNotifierProvider);
    if (state.hasError && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete category: ${state.error}')),
      );
    }
  }
}

class _CategoryForm extends StatelessWidget {
  const _CategoryForm({
    required this.formKey,
    required this.nameController,
    required this.iconController,
    required this.colorController,
    required this.type,
    required this.onTypeChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController iconController;
  final TextEditingController colorController;
  final CategoryType type;
  final ValueChanged<CategoryType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Category name'),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<CategoryType>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(
                value: CategoryType.expense,
                child: Text('Expense'),
              ),
              DropdownMenuItem(
                value: CategoryType.income,
                child: Text('Income'),
              ),
            ],
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: iconController,
            decoration: const InputDecoration(labelText: 'Icon key'),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Icon is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: colorController,
            decoration: const InputDecoration(labelText: 'Color hex'),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Color is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
