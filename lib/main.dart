import 'package:finora/core/errors/global_error_handler.dart';
import 'package:finora/core/theme/app_theme.dart';
import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/utils/money_formatter.dart';
import 'package:finora/core/widgets/finora_card.dart';
import 'package:finora/core/widgets/finora_page_scaffold.dart';
import 'package:finora/core/widgets/finora_skeleton.dart';
import 'package:flutter/material.dart';

void main() {
  runWithGlobalErrorGuard<void>(() {
    WidgetsFlutterBinding.ensureInitialized();
    installGlobalErrorHandlers();
    runApp(const FinoraApp());
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
      home: const DashboardShell(),
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  DateTime _selectedMonth = DateTime(2026, 2);
  bool _showLoading = false;

  void _onMonthChanged(DateTime month) => setState(() => _selectedMonth = month);
  void _toggleLoading() => setState(() => _showLoading = !_showLoading);

  Future<void> _openAddTransactionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Transaction'),
        content: const Text('Shared dialog motion and theme styles are active.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FinoraPageScaffold(
      title: 'Overview',
      subtitle: 'Epic 8 widget system baseline',
      selectedMonth: _selectedMonth,
      onMonthChanged: _onMonthChanged,
      trailing: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          OutlinedButton(
            onPressed: _toggleLoading,
            child: Text(_showLoading ? 'Show Data' : 'Show Loading'),
          ),
          FilledButton(
            onPressed: _openAddTransactionDialog,
            child: const Text('Add Transaction'),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useSplit = constraints.maxWidth >= 900;
          return AnimatedSwitcher(
            duration: AppMotion.normal,
            switchInCurve: AppMotion.emphasized,
            switchOutCurve: AppMotion.standard,
            child: useSplit
                ? Row(
                    key: const ValueKey('split'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _BalancePanel(loading: _showLoading)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: _InsightPanel(loading: _showLoading)),
                    ],
                  )
                : Column(
                    key: const ValueKey('stacked'),
                    children: [
                      _BalancePanel(loading: _showLoading),
                      const SizedBox(height: AppSpacing.lg),
                      _InsightPanel(loading: _showLoading),
                    ],
                  ));
        },
      ),
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FinoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: loading
            ? const [
                FinoraSkeletonBox(width: 140, height: 20),
                SizedBox(height: AppSpacing.sm),
                FinoraSkeletonBox(width: 200, height: 40),
                SizedBox(height: AppSpacing.md),
                FinoraSkeletonBox(width: 120, height: 16),
              ]
            : [
                Text('Net Balance', style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  MoneyFormatter.format(12420.80),
                  style: textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${MoneyFormatter.format(4.2, showPlus: true, decimalDigits: 1, currencySymbol: '')}% vs last month',
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.income),
                ),
              ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FinoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: loading
            ? const [
                FinoraSkeletonBox(width: 120, height: 20),
                SizedBox(height: AppSpacing.sm),
                FinoraSkeletonBox(width: 260, height: 26),
                SizedBox(height: AppSpacing.md),
                FinoraSkeletonBox(width: 280, height: 16),
              ]
            : [
                Text('Top Insight', style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Dining expenses increased this month.',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Use this panel for empty/loading/error variants in Epic 3.',
                  style: textTheme.bodyMedium,
                ),
              ],
      ),
    );
  }
}
