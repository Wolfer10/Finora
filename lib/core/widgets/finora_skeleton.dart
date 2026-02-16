import 'package:flutter/material.dart';

import 'package:finora/core/theme/app_tokens.dart';

class FinoraSkeletonBox extends StatefulWidget {
  const FinoraSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadii.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<FinoraSkeletonBox> createState() => _FinoraSkeletonBoxState();
}

class _FinoraSkeletonBoxState extends State<FinoraSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 0.9).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
