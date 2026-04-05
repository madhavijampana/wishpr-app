import 'package:flutter/material.dart';

/// Shown after a successful speech trigger (consumer vs developer copy).
class GuardMatchSuccessCard extends StatelessWidget {
  const GuardMatchSuccessCard({
    super.key,
    required this.developerMode,
    required this.bannerLine,
    required this.executionSummary,
    required this.finalStatus,
    required this.colorScheme,
  });

  final bool developerMode;
  final String bannerLine;
  final String? executionSummary;
  final String? finalStatus;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: colorScheme.primary.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    developerMode
                        ? bannerLine
                        : 'Trigger matched — your safety plan ran.',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                if (developerMode &&
                    finalStatus != null &&
                    finalStatus!.isNotEmpty)
                  Chip(
                    label: Text(
                      finalStatus!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    backgroundColor: colorScheme.surface.withValues(alpha: 0.35),
                    side: BorderSide.none,
                    labelStyle: TextStyle(color: colorScheme.primary),
                  ),
              ],
            ),
            if (developerMode &&
                executionSummary != null &&
                executionSummary!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Actions run',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                executionSummary!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                  height: 1.45,
                ),
              ),
            ],
            if (!developerMode) ...[
              const SizedBox(height: 8),
              Text(
                'Open History for a full breakdown.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
