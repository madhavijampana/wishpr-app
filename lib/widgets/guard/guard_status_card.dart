import 'package:flutter/material.dart';

/// Friendly-only status copy (no technical details).
class GuardStatusCard extends StatelessWidget {
  const GuardStatusCard({
    super.key,
    required this.title,
    required this.body,
    required this.colorScheme,
  });

  final String title;
  final String body;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.65),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
