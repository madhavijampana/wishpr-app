import 'package:flutter/material.dart';

import 'guard_debug_line.dart';

/// All strings needed to render developer diagnostics (Guard Mode).
class GuardDiagnosticsSnapshot {
  const GuardDiagnosticsSnapshot({
    required this.micDebugLine,
    required this.speechEngineLine,
    required this.speechStatusLine,
    required this.speechLastErrorLine,
    required this.listening,
    required this.isListeningNow,
    required this.liveText,
    required this.activePhraseCount,
    required this.stMicGranted,
    required this.stSpeechInit,
    required this.stListening,
    required this.stPartialTranscript,
    required this.stFinalTranscript,
    required this.stLastCallbackKind,
    required this.stLatestRecognized,
    required this.stNormalized,
    required this.stNormalizedFlex,
    required this.stMatcherNormPhrase,
    required this.stMatcherStringSim,
    required this.stMatcherTokenOverlap,
    required this.stMatcherFuzzyKw,
    required this.stMatcherFinalScore,
    required this.stMatcherThreshold,
    required this.stMatcherReason,
    required this.stPhraseCount,
    required this.stLoadedPhraseTexts,
    required this.stMatchAttempt,
    required this.stMatchedPhrase,
    required this.stActionEngine,
    required this.stFirestoreWrite,
    required this.stLastException,
  });

  final String micDebugLine;
  final String speechEngineLine;
  final String speechStatusLine;
  final String speechLastErrorLine;
  final bool listening;
  final bool isListeningNow;
  final String liveText;
  final int activePhraseCount;
  final String stMicGranted;
  final String stSpeechInit;
  final String stListening;
  final String stPartialTranscript;
  final String stFinalTranscript;
  final String stLastCallbackKind;
  final String stLatestRecognized;
  final String stNormalized;
  final String stNormalizedFlex;
  final String stMatcherNormPhrase;
  final String stMatcherStringSim;
  final String stMatcherTokenOverlap;
  final String stMatcherFuzzyKw;
  final String stMatcherFinalScore;
  final String stMatcherThreshold;
  final String stMatcherReason;
  final String stPhraseCount;
  final String stLoadedPhraseTexts;
  final String stMatchAttempt;
  final String stMatchedPhrase;
  final String stActionEngine;
  final String stFirestoreWrite;
  final String stLastException;
}

class GuardDiagnosticsPanel extends StatelessWidget {
  const GuardDiagnosticsPanel({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.data,
    required this.onRefreshMic,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final GuardDiagnosticsSnapshot data;
  final VoidCallback onRefreshMic;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: false,
        title: Text(
          'Developer Diagnostics',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Transcripts, scores, thresholds, and engine data',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.55),
          ),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          GuardDebugLine(
            label: 'Microphone permission',
            value: data.micDebugLine,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: 'Speech engine',
            value: data.speechEngineLine,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: 'Speech status',
            value: data.speechStatusLine,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: 'Listening (session)',
            value: data.listening
                ? (data.isListeningNow ? 'Active' : 'Between sessions')
                : 'Off',
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: 'Last speech error',
            value: data.speechLastErrorLine,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRefreshMic,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh mic status'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onPrimaryContainer,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          if (data.listening) ...[
            const SizedBox(height: 12),
            Text(
              'Live transcript',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              data.liveText.isEmpty
                  ? '(empty — waiting for engine)'
                  : data.liveText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${data.activePhraseCount} active '
              '${data.activePhraseCount == 1 ? 'phrase' : 'phrases'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.65),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Speech trigger trace',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use Test on this screen or Settings → Debug for a sample row.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.65),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          GuardDebugLine(
            label: '1. Microphone permission granted',
            value: data.stMicGranted,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '2. Speech engine initialized',
            value: data.stSpeechInit,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '3. Listening active',
            value: data.stListening,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '4. Partial transcript (latest partial callback)',
            value: data.stPartialTranscript,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '5. Final transcript (latest final callback)',
            value: data.stFinalTranscript,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '6. Last engine callback',
            value: data.stLastCallbackKind,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '7. Latest recognized text (current utterance)',
            value: data.stLatestRecognized,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '8. Normalized recognized (basic)',
            value: data.stNormalized,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '9. Normalized recognized (flexible: collapse repeats)',
            value: data.stNormalizedFlex,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '10. Matcher: normalized saved phrase (flex, best)',
            value: data.stMatcherNormPhrase,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '11. Matcher: string similarity score',
            value: data.stMatcherStringSim,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '12. Matcher: token overlap score',
            value: data.stMatcherTokenOverlap,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '13. Matcher: fuzzy keyword score',
            value: data.stMatcherFuzzyKw,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '14. Matcher: final chosen score',
            value: data.stMatcherFinalScore,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '15. Matcher: threshold used',
            value: data.stMatcherThreshold,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '16. Matcher: reason (match / no match)',
            value: data.stMatcherReason,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '17. Phrases loaded from Firestore (count)',
            value: data.stPhraseCount,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '18. Loaded phrase texts',
            value: data.stLoadedPhraseTexts,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '19. Phrase match attempt result',
            value: data.stMatchAttempt,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '20. Matched phrase id · label',
            value: data.stMatchedPhrase,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '21. Action engine execution',
            value: data.stActionEngine,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '22. Firestore trigger_event write',
            value: data.stFirestoreWrite,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          GuardDebugLine(
            label: '23. Last exception message',
            value: data.stLastException,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}
