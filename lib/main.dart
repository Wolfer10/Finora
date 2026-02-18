import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/errors/global_error_handler.dart';
import 'package:finora/core/theme/app_theme.dart';
import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/utils/money_formatter.dart';
import 'package:finora/core/widgets/finora_page_scaffold.dart';
import 'package:finora/features/accounts/presentation/accounts_screen.dart';
import 'package:finora/features/categories/presentation/categories_screen.dart';
import 'package:finora/features/goals/presentation/goals_screen.dart';
import 'package:finora/features/insights/presentation/insights_screen.dart';
import 'package:finora/features/transactions/presentation/dashboard_overview.dart';
import 'package:finora/features/transactions/presentation/transactions_providers.dart';
import 'package:finora/features/transactions/presentation/transactions_screen.dart';

void main() {
  runWithGlobalErrorGuard<void>(() {
    WidgetsFlutterBinding.ensureInitialized();
    installGlobalErrorHandlers();
    runApp(const ProviderScope(child: FinoraApp()));
  });
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const FinoraEpic3Shell(),
    );
  }
}

class FinoraEpic3Shell extends ConsumerStatefulWidget {
  const FinoraEpic3Shell({super.key});

  @override
  ConsumerState<FinoraEpic3Shell> createState() => _FinoraEpic3ShellState();
}

class _FinoraEpic3ShellState extends ConsumerState<FinoraEpic3Shell> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(transactionBootstrapProvider);
    final appSettings = ref.watch(appSettingsProvider);
    appSettings.whenData((settings) {
      MoneyFormatter.configureDefaults(
        currencyCode: settings.currencyCode,
        currencySymbol: settings.currencySymbol,
      );
    });
    final selectedMonth = ref.watch(selectedMonthProvider);
    final pageTitle = switch (_selectedTab) {
      0 => 'Overview',
      1 => 'Transactions',
      2 => 'Goals',
      3 => 'Insights',
      4 => 'Accounts',
      _ => 'Categories',
    };

    return FinoraPageScaffold(
      title: pageTitle,
      subtitle: 'Goals, surplus allocation, and insights',
      selectedMonth: selectedMonth,
      onMonthChanged: (month) {
        ref.read(selectedMonthProvider.notifier).state = DateTime(
              month.year,
              month.month,
            );
      },
      trailing: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          ChoiceChip(
            label: const Text('Overview'),
            selected: _selectedTab == 0,
            onSelected: (_) => setState(() => _selectedTab = 0),
          ),
          ChoiceChip(
            label: const Text('Transactions'),
            selected: _selectedTab == 1,
            onSelected: (_) => setState(() => _selectedTab = 1),
          ),
          ChoiceChip(
            label: const Text('Goals'),
            selected: _selectedTab == 2,
            onSelected: (_) => setState(() => _selectedTab = 2),
          ),
          ChoiceChip(
            label: const Text('Insights'),
            selected: _selectedTab == 3,
            onSelected: (_) => setState(() => _selectedTab = 3),
          ),
          ChoiceChip(
            label: const Text('Accounts'),
            selected: _selectedTab == 4,
            onSelected: (_) => setState(() => _selectedTab = 4),
          ),
          ChoiceChip(
            label: const Text('Categories'),
            selected: _selectedTab == 5,
            onSelected: (_) => setState(() => _selectedTab = 5),
          ),
          if (_selectedTab == 1)
            FilledButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => const AddExpenseDialog(),
                );
              },
              child: const Text('Add Expense'),
            ),
          if (_selectedTab == 2)
            FilledButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => const AddGoalDialog(),
                );
              },
              child: const Text('Add Goal'),
            ),
          if (_selectedTab == 4)
            FilledButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => const AddAccountDialog(),
                );
              },
              child: const Text('Add Account'),
            ),
          if (_selectedTab == 5)
            FilledButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => const AddCategoryDialog(),
                );
              },
              child: const Text('Add Category'),
            ),
          PopupMenuButton<_TopBarAction>(
            tooltip: 'More actions',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleTopBarAction(action, selectedMonth),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _TopBarAction.settings,
                child: Text('Settings'),
              ),
              PopupMenuItem(
                value: _TopBarAction.exportJson,
                child: Text('Export JSON'),
              ),
              PopupMenuItem(
                value: _TopBarAction.importJson,
                child: Text('Import JSON'),
              ),
              PopupMenuItem(
                value: _TopBarAction.closeMonth,
                child: Text('Close Month'),
              ),
            ],
          ),
        ],
      ),
      child: bootstrap.when(
        data: (_) {
          if (_selectedTab == 0) {
            return const DashboardOverview();
          }
          if (_selectedTab == 1) {
            return const TransactionsScreen();
          }
          if (_selectedTab == 2) {
            return const GoalsScreen();
          }
          if (_selectedTab == 3) {
            return const InsightsScreen();
          }
          if (_selectedTab == 4) {
            return const AccountsScreen();
          }
          return const CategoriesScreen();
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Text(
          'Initialization failed: $error',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = await ref.read(dataTransferNotifierProvider.notifier).exportJson();
      if (!context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('JSON Export'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: SelectableText(json),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleTopBarAction(
    _TopBarAction action,
    DateTime selectedMonth,
  ) async {
    switch (action) {
      case _TopBarAction.settings:
        await _showSettingsDialog(context);
        break;
      case _TopBarAction.exportJson:
        await _showExportDialog(context);
        break;
      case _TopBarAction.importJson:
        await _showImportDialog(context);
        break;
      case _TopBarAction.closeMonth:
        await _closeMonth(selectedMonth);
        break;
    }
  }

  Future<void> _closeMonth(DateTime selectedMonth) async {
    try {
      final result = await ref
          .read(transactionNotifierProvider.notifier)
          .closeMonth(selectedMonth);
      if (!context.mounted) {
        return;
      }
      final allocated = result.allocatedAmount.toStringAsFixed(2);
      final createdCount = result.createdContributions.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Month closed. Allocated $allocated across $createdCount goal contributions.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Close month failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => const _SettingsDialog(),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final controller = TextEditingController();
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import JSON'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 14,
            maxLines: 20,
            decoration: const InputDecoration(
              hintText: 'Paste export JSON here',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (shouldImport != true) {
      controller.dispose();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(dataTransferNotifierProvider.notifier).importJson(controller.text);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Import completed.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Import failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

enum _TopBarAction {
  settings,
  exportJson,
  importJson,
  closeMonth,
}

class _SettingsDialog extends ConsumerStatefulWidget {
  const _SettingsDialog();

  @override
  ConsumerState<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog> {
  final _currencyCodeController = TextEditingController();
  final _currencySymbolController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _currencyCodeController.dispose();
    _currencySymbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final saveState = ref.watch(settingsNotifierProvider);

    if (!_initialized && settingsAsync.hasValue) {
      final settings = settingsAsync.value!;
      _currencyCodeController.text = settings.currencyCode;
      _currencySymbolController.text = settings.currencySymbol;
      _initialized = true;
    }

    return AlertDialog(
      title: const Text('App Settings'),
      content: SizedBox(
        width: 420,
        child: settingsAsync.when(
          data: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currencyCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Currency code',
                  hintText: 'USD, EUR, HUF...',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _currencySymbolController,
                decoration: const InputDecoration(
                  labelText: 'Currency symbol',
                  hintText: r'$, EUR symbol, Ft...',
                ),
              ),
            ],
          ),
          loading: () => const Row(
            children: [
              SizedBox.square(
                dimension: AppSizes.iconMd,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(child: Text('Loading settings...')),
            ],
          ),
          error: (error, _) => Text(
            'Failed to load settings: $error',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.error),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saveState is AsyncLoading ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final currencyCode = _currencyCodeController.text.trim().toUpperCase();
    final currencySymbol = _currencySymbolController.text.trim();
    if (currencyCode.isEmpty || currencySymbol.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Currency code and symbol are required.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await ref.read(settingsNotifierProvider.notifier).updateCurrency(
          currencyCode: currencyCode,
          currencySymbol: currencySymbol,
        );
    final saveState = ref.read(settingsNotifierProvider);
    if (saveState.hasError) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Settings update failed: ${saveState.error}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Settings saved.')),
      );
    }
  }
}
