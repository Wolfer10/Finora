import 'package:flutter/material.dart';

import 'package:finora/core/theme/app_tokens.dart';

class FinoraSectionHeader extends StatelessWidget {
  const FinoraSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 560;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: textTheme.bodyMedium),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.md),
                trailing!,
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: textTheme.bodyMedium),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        );
      },
    );
  }
}
