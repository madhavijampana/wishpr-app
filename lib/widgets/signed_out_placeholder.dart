import 'package:flutter/material.dart';

import '../theme/wishpr_constants.dart';

/// Centered message when Firestore tabs need an authenticated user.
class SignedOutPlaceholder extends StatelessWidget {
  const SignedOutPlaceholder({super.key, this.title, this.body});

  final String? title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WishprLayout.screenPaddingH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: cs.primary.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Sign in required',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body ?? WishprFirestoreCopy.signInRequired,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
