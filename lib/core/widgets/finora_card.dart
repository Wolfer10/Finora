import 'package:flutter/material.dart';

import 'package:finora/core/theme/app_tokens.dart';

class FinoraCard extends StatelessWidget {
  const FinoraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
