import 'package:flutter/material.dart';

import '../theme/wishpr_constants.dart';

/// Gradient Wishpr title for hero sections.
class WishprWordmark extends StatelessWidget {
  const WishprWordmark({
    super.key,
    this.fontSize = 40,
  });

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
      ],
    );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          gradient.createShader(Offset.zero & bounds.size),
      child: Text(
        WishprStrings.appName,
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineLarge?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          height: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}
