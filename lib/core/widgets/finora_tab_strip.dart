import 'package:flutter/material.dart';

import 'package:finora/core/theme/app_tokens.dart';

class FinoraTabStrip extends StatelessWidget implements PreferredSizeWidget {
  const FinoraTabStrip({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
  });

  final List<Tab> tabs;
  final TabController? controller;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable,
      labelPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.minTapTarget + AppSpacing.xs);
}
