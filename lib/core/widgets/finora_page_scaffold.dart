import 'package:flutter/material.dart';

import 'package:finora/core/theme/app_tokens.dart';
import 'package:finora/core/widgets/finora_month_selector.dart';
import 'package:finora/core/widgets/finora_section_header.dart';

class FinoraPageScaffold extends StatelessWidget {
  const FinoraPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.selectedMonth,
    this.onMonthChanged,
    this.maxWidth = 1100,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final DateTime? selectedMonth;
  final ValueChanged<DateTime>? onMonthChanged;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final showMonthSelector = selectedMonth != null && onMonthChanged != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.normal,
            curve: AppMotion.emphasized,
            builder: (context, value, _) {
              final y = 12 * (1 - value);
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, y),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FinoraSectionHeader(
                              title: title,
                              subtitle: subtitle,
                              trailing: trailing,
                            ),
                            if (showMonthSelector) ...[
                              const SizedBox(height: AppSpacing.lg),
                              FinoraMonthSelector(
                                selectedMonth: selectedMonth!,
                                onChanged: onMonthChanged!,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
