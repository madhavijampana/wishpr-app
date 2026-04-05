import 'package:flutter/material.dart';

class GuardDebugLine extends StatelessWidget {
  const GuardDebugLine({
    super.key,
    required this.label,
    required this.value,
    required this.theme,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
