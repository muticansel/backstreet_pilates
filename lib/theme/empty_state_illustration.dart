import 'package:flutter/material.dart';

/// A quiet studio moment reused in member-facing empty states.
class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({super.key, this.height = 116});

  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Image.asset(
          'assets/images/empty_state_reformer.png',
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );
}
