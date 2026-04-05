import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/actions/action_execution_result.dart';
import '../models/actions/phrase_guard_action.dart';
import '../models/firestore/trigger_event_document.dart';
import '../theme/wishpr_constants.dart';

String _sourceDetail(TriggerEventSource s) {
  switch (s) {
    case TriggerEventSource.test:
      return 'Test — sample row from Settings → Debug (no live actions).';
    case TriggerEventSource.speech:
      return 'Speech — secret phrase matched while Guard Mode was listening.';
    case TriggerEventSource.timer:
      return 'Timer Fail-Safe — countdown ended without I’m Safe, or a cancellation was logged.';
    case TriggerEventSource.quickTrigger:
      return 'Quick Trigger — discreet in-app emergency path (triple-tap title or long-press bolt).';
  }
}

/// Full breakdown of one history item: phrase, speech, location, per-action results.
class TriggerDetailScreen extends StatelessWidget {
  const TriggerDetailScreen({super.key, required this.trigger});

  final TriggerEventDocument trigger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final results = trigger.parsedExecutionResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trigger details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WishprLayout.screenPaddingH,
          16,
          WishprLayout.screenPaddingH,
          WishprLayout.screenPaddingV,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trigger.phraseLabel.isNotEmpty
                      ? trigger.phraseLabel
                      : 'Trigger',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trigger.status.isNotEmpty)
                Chip(
                  label: Text(trigger.status),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: cs.secondary.withValues(alpha: 0.2),
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    color: cs.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (trigger.phraseText.isNotEmpty)
            Text(
              '"${trigger.phraseText}"',
              style: theme.textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 16),
          if (trigger.source != null) ...[
            _sectionTitle(theme, 'Source'),
            const SizedBox(height: 6),
            Text(
              _sourceDetail(trigger.source!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.78),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _sectionTitle(theme, 'When'),
          const SizedBox(height: 6),
          Text(
            trigger.whenLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
          if (trigger.recognizedSpeech != null &&
              trigger.recognizedSpeech!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle(theme, 'Recognized speech'),
            const SizedBox(height: 6),
            Text(
              trigger.recognizedSpeech!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          _sectionTitle(theme, 'Configured actions'),
          const SizedBox(height: 6),
          Text(
            trigger.actionSummary,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          if (trigger.executionSummary.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle(theme, 'Execution summary'),
            const SizedBox(height: 6),
            Text(
              trigger.executionSummary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
          if (trigger.locationSnapshot != null) ...[
            const SizedBox(height: 16),
            _sectionTitle(theme, 'Captured location'),
            const SizedBox(height: 6),
            Text(
              trigger.locationSnapshot!.shortLabel,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (results.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle(theme, 'Action results'),
            const SizedBox(height: 8),
            ...results.map((r) => _resultTile(theme, cs, r)),
          ],
        ],
      ),
    );
  }

  List<Widget> _smsPerContactRows(
    ThemeData theme,
    ColorScheme cs,
    List<dynamic> raw,
  ) {
    final out = <Widget>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final name = m['contactName'] as String? ?? '';
      final phone = m['targetPhone'] as String? ?? '';
      final outcome = m['outcome'] as String? ?? '';
      final msg = m['message'] as String? ?? '';
      final label = [
        if (name.isNotEmpty) name,
        if (phone.isNotEmpty) phone,
      ].join(' · ');
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.isEmpty ? 'Contact' : label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    outcome.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _smsOutcomeColor(cs, outcome),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return out;
  }

  Color _smsOutcomeColor(ColorScheme cs, String outcome) {
    switch (outcome) {
      case 'sentDirect':
        return cs.primary;
      case 'fallbackComposer':
        return cs.secondary;
      case 'failed':
        return cs.error;
      default:
        return cs.onSurfaceVariant;
    }
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _resultTile(
    ThemeData theme,
    ColorScheme cs,
    ActionExecutionResult r,
  ) {
    final icon = _statusIcon(r.status);
    final color = _statusColor(cs, r.status);
    final d = r.detail;
    final contactName = d?['contactName'] as String?;
    final contactPhone = d?['targetPhone'] as String?;
    final hasContactLine =
        contactName != null && contactName.isNotEmpty;
    final contactLineText = hasContactLine
        ? (contactPhone != null && contactPhone.isNotEmpty
            ? 'Contact: $contactName · $contactPhone'
            : 'Contact: $contactName')
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _actionTitle(r.action),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.35,
                        color: cs.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                    if (hasContactLine) ...[
                      const SizedBox(height: 6),
                      Text(
                        contactLineText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (r.action == PhraseGuardAction.sendSms &&
                        d?['smsPerContact'] is List) ...[
                      const SizedBox(height: 10),
                      ..._smsPerContactRows(
                        theme,
                        cs,
                        d!['smsPerContact'] as List,
                      ),
                    ],
                    if (r.executedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('MMM d, y · h:mm:ss a')
                            .format(r.executedAt!.toLocal()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      r.status.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _actionTitle(PhraseGuardAction a) {
    switch (a) {
      case PhraseGuardAction.shareLocation:
        return 'Share location';
      case PhraseGuardAction.sendSms:
        return 'Send SMS';
      case PhraseGuardAction.callContact:
        return 'Call contact';
      case PhraseGuardAction.startRecording:
        return 'Start recording';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'failed':
        return Icons.error_rounded;
      case 'queued':
        return Icons.pending_actions_rounded;
      case 'prepared':
        return Icons.call_made_rounded;
      case 'deferred':
        return Icons.schedule_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _statusColor(ColorScheme cs, String status) {
    switch (status) {
      case 'success':
        return cs.primary;
      case 'failed':
        return cs.error;
      case 'queued':
      case 'prepared':
        return cs.secondary;
      case 'deferred':
        return cs.tertiary;
      default:
        return cs.onSurfaceVariant;
    }
  }
}
