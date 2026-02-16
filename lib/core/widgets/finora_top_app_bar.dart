import 'package:flutter/material.dart';

import 'package:finora/core/theme/app_tokens.dart';

class FinoraTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FinoraTopAppBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      toolbarHeight: AppSizes.minTapTarget + AppSpacing.sm,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.minTapTarget + AppSpacing.sm);
}
