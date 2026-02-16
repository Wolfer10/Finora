import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:finora/core/theme/app_tokens.dart';

class FinoraMonthSelector extends StatelessWidget {
  const FinoraMonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
  });

  final DateTime selectedMonth;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final months = <DateTime>[
      DateTime(selectedMonth.year, selectedMonth.month - 1),
      DateTime(selectedMonth.year, selectedMonth.month),
      DateTime(selectedMonth.year, selectedMonth.month + 1),
    ];
    final formatter = DateFormat('MMM yyyy');

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: months.map((month) {
        final isSelected = month.year == selectedMonth.year &&
            month.month == selectedMonth.month;
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: ChoiceChip(
            label: Text(formatter.format(month)),
            selected: isSelected,
            onSelected: (_) => onChanged(month),
          ),
        );
      }).toList(growable: false),
    );
  }
}
