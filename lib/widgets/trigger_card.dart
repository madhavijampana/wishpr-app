import 'package:flutter/material.dart';

import '../models/firestore/trigger_event_document.dart';

class TriggerCard extends StatelessWidget {
  const TriggerCard({
    super.key,
    required this.trigger,
    required this.theme,
    required this.cs,
    this.onOpenDetail,
  });

  final TriggerEventDocument trigger;
  final ThemeData theme;
  final ColorScheme cs;
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final hasLabel = trigger.phraseLabel.isNotEmpty;
    final hasText = trigger.phraseText.isNotEmpty;
    final outcomeText = trigger.executionSummary.isNotEmpty
        ? trigger.executionSummary
        : trigger.actionSummary;

    final content = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                color: cs.secondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasLabel && hasText) ...[
                      Text(
                        trigger.phraseLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"${trigger.phraseText}"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (hasText) ...[
                      Text(
                        '"${trigger.phraseText}"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (hasLabel) ...[
                      Text(
                        '"${trigger.phraseLabel}"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trigger.status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Chip(
                    label: Text(
                      trigger.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: cs.secondary.withValues(alpha: 0.2),
                    side: BorderSide.none,
                    labelStyle: TextStyle(color: cs.secondary),
                  ),
                ),
              if (trigger.source != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Chip(
                    label: Text(
                      trigger.source == TriggerEventSource.test
                          ? 'Test'
                          : 'Speech',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: trigger.source == TriggerEventSource.test
                        ? cs.tertiary.withValues(alpha: 0.22)
                        : cs.primary.withValues(alpha: 0.18),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: trigger.source == TriggerEventSource.test
                          ? cs.tertiary
                          : cs.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 6),
              Text(
                trigger.whenLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
              if (onOpenDetail != null) ...[
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: cs.outline.withValues(alpha: 0.25)),
          const SizedBox(height: 8),
          Text(
            outcomeText,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: cs.onSurface.withValues(alpha: 0.88),
            ),
          ),
          if (trigger.executionSummary.isNotEmpty &&
              trigger.actionSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Planned: ${trigger.actionSummary}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );

    if (onOpenDetail == null) {
      return Card(child: content);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: content,
      ),
    );
  }
}
