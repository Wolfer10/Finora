import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/errors/global_error_handler.dart';
import 'package:finora/core/theme/app_theme.dart';
import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/widgets/finora_page_scaffold.dart';
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
    final selectedMonth = ref.watch(selectedMonthProvider);

    return FinoraPageScaffold(
      title: _selectedTab == 0 ? 'Overview' : 'Transactions',
      subtitle: 'Epic 3 transactions vertical slice',
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
          FilledButton(
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (context) => const AddExpenseDialog(),
              );
            },
            child: const Text('Add Expense'),
          ),
        ],
      ),
      child: bootstrap.when(
        data: (_) {
          if (_selectedTab == 0) {
            return const DashboardOverview();
          }
          return const TransactionsScreen();
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
}
