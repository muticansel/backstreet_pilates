import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

class PilatesLoadingIndicator extends StatefulWidget {
  const PilatesLoadingIndicator({super.key, this.size = 56});

  final double size;

  @override
  State<PilatesLoadingIndicator> createState() =>
      _PilatesLoadingIndicatorState();
}

class _PilatesLoadingIndicatorState extends State<PilatesLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final wave = math.sin(_controller.value * math.pi);
          return Transform.translate(
            offset: Offset(0, -6 * wave),
            child: Transform.rotate(angle: .08 * wave, child: child),
          );
        },
        child: Icon(Icons.self_improvement_outlined,
            color: AppTheme.sage, size: widget.size),
      );
}
