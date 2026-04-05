import 'package:flutter/material.dart';

class GuardSetupSummaryCard extends StatelessWidget {
  const GuardSetupSummaryCard({
    super.key,
    required this.activePhrases,
    required this.trustedContacts,
    required this.actionsSummary,
    required this.timerFailsafeActive,
    required this.colorScheme,
  });

  final int activePhrases;
  final int trustedContacts;
  final String actionsSummary;
  final bool timerFailsafeActive;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Safety Setup',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _row(theme, 'Active phrases', '$activePhrases'),
          _row(theme, 'Trusted contacts', '$trustedContacts'),
          _row(theme, 'Enabled actions', actionsSummary),
          _row(
            theme,
            'Timer Fail-Safe',
            timerFailsafeActive ? 'Running' : 'Off',
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              k,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.62),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
