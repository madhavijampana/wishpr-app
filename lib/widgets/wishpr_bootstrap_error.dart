import 'package:flutter/material.dart';

import '../theme/wishpr_colors.dart';
import '../theme/wishpr_constants.dart';

/// Shown when startup (e.g. Firebase) fails; avoids a blank or crashed launch.
class WishprBootstrapError extends StatelessWidget {
  const WishprBootstrapError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: WishprColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WishprLayout.screenPaddingH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 52,
                color: theme.colorScheme.error.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 20),
              Text(
                'Wishpr couldn’t start',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
