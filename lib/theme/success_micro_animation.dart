import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A short, non-blocking acknowledgement for completed actions.
///
/// It honours the platform reduce-motion preference and remains readable as a
/// regular success message when animation is disabled.
class SuccessMicroAnimation extends StatefulWidget {
  const SuccessMicroAnimation({super.key, required this.message});

  final String message;

  @override
  State<SuccessMicroAnimation> createState() => _SuccessMicroAnimationState();
}

class _SuccessMicroAnimationState extends State<SuccessMicroAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final icon = _SuccessMark(animation: _controller, animated: !reduceMotion);
    return Semantics(
      liveRegion: true,
      label: widget.message,
      child: Row(children: [
        ExcludeSemantics(child: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(widget.message,
              style: const TextStyle(color: Colors.white, height: 1.3)),
        ),
      ]),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark({required this.animation, required this.animated});

  final Animation<double> animation;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    if (!animated) return const _CheckCircle(scale: 1, ringOpacity: 0);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curve = Curves.easeOutCubic.transform(animation.value);
        return _CheckCircle(
          scale: 0.72 + (0.28 * curve),
          ringOpacity: (1 - curve) * 0.42,
          ringScale: 0.8 + (curve * 0.7),
        );
      },
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({
    required this.scale,
    required this.ringOpacity,
    this.ringScale = 1,
  });

  final double scale;
  final double ringOpacity;
  final double ringScale;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 32,
        height: 32,
        child: Stack(alignment: Alignment.center, children: [
          Transform.scale(
            scale: ringScale,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: ringOpacity),
                  width: 2,
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: scale,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F0E4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppTheme.sage, size: 18),
            ),
          ),
        ]),
      );
}
