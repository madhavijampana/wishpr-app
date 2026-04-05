import 'package:flutter/material.dart';

import '../theme/wishpr_constants.dart';

/// Pinned primary action for full-screen forms (Wishpr shell).
class WishprFormBottomBar extends StatelessWidget {
  const WishprFormBottomBar({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      elevation: 8,
      shadowColor: Colors.black54,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            WishprLayout.screenPaddingH,
            12,
            WishprLayout.screenPaddingH,
            16,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
