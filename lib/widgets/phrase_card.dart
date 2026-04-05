import 'package:flutter/material.dart';

import '../models/firestore/phrase_document.dart';
import '../theme/wishpr_constants.dart';

class PhraseCard extends StatelessWidget {
  const PhraseCard({
    super.key,
    required this.phrase,
    required this.cs,
    required this.theme,
    this.onTap,
  });

  final PhraseDocument phrase;
  final ColorScheme cs;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WishprLayout.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(WishprLayout.iconTileRadius),
                ),
                child: Icon(
                  Icons.format_quote_rounded,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phrase.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      phrase.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (phrase.sendSms &&
                        phrase.smsContactIds.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'SMS → ${phrase.smsContactIds.length} trusted contact'
                        '${phrase.smsContactIds.length == 1 ? '' : 's'}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.primary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (phrase.callContact &&
                        phrase.callContactIds.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Call → ${phrase.callContactIds.length} trusted contact'
                        '${phrase.callContactIds.length == 1 ? '' : 's'}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.secondary.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (phrase.voiceSamples.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${phrase.voiceSamples.length} voice sample'
                        '${phrase.voiceSamples.length == 1 ? '' : 's'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PhraseStatusChip(active: phrase.active),
            ],
          ),
        ),
      ),
    );
  }
}

class PhraseStatusChip extends StatelessWidget {
  const PhraseStatusChip({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(
        active ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded,
        size: 18,
        color: active ? cs.secondary : cs.onSurface.withValues(alpha: 0.45),
      ),
      label: Text(active ? 'Active' : 'Inactive'),
      side: BorderSide.none,
      backgroundColor: active
          ? cs.secondary.withValues(alpha: 0.18)
          : cs.surfaceContainerHighest,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: active ? cs.secondary : cs.onSurface.withValues(alpha: 0.55),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
