import 'package:flutter/material.dart';

import '../screens/timer_failsafe_screen.dart';
import '../theme/wishpr_constants.dart';
import 'quick_trigger_feedback.dart';
import 'wishpr_safety_host.dart';

/// Home “Protection Center” entry points: Timer Fail-Safe + Quick Trigger status.
class ProtectionCenterCard extends StatelessWidget {
  const ProtectionCenterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scope = WishprSafetyScope.maybeOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(WishprLayout.guardCardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.tertiaryContainer.withValues(alpha: 0.85),
            cs.primaryContainer.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(
          color: cs.tertiary.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: scope == null
            ? Text(
                'Safety services loading…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_rounded,
                          color: cs.tertiary, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Protection Center',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onLongPress: () async {
                          final r = await scope.quick.fire();
                          if (!context.mounted) return;
                          showQuickTriggerAttemptFeedback(context, r);
                        },
                        child: Icon(
                          Icons.bolt_rounded,
                          color: cs.tertiary.withValues(alpha: 0.9),
                          size: 28,
                          semanticLabel: 'Quick Trigger long-press',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onLongPress: () async {
                      final r = await scope.quick.fire();
                      if (!context.mounted) return;
                      showQuickTriggerAttemptFeedback(context, r);
                    },
                    child: Text(
                      'Guard Mode listens for phrases. Timer Fail-Safe runs actions '
                      'if you don’t check in. Quick Trigger uses your chosen phrase — '
                      'triple-tap the Wishpr title or long-press the bolt (availability varies by device).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onTertiaryContainer.withValues(alpha: 0.88),
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListenableBuilder(
                    listenable:
                        Listenable.merge([scope.timer, scope.quick]),
                    builder: (context, _) {
                      final lines = <String>[];
                      if (scope.timer.isRunning) {
                        lines.add('Timer Fail-Safe: running');
                      } else if (scope.timer.isHandlingDeadline) {
                        lines.add('Timer Fail-Safe: triggered');
                      } else {
                        lines.add('Timer Fail-Safe: idle');
                      }
                      if (scope.quick.inCooldown) {
                        final w = scope.quick.cooldownRemaining;
                        final secs = w?.inSeconds ?? 0;
                        lines.add('Quick Trigger: cooldown (${secs}s)');
                      } else if (scope.quick.isBusy) {
                        lines.add('Quick Trigger: sending…');
                      } else {
                        lines.add('Quick Trigger: ready');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: lines
                            .map(
                              (l) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  l,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: cs.onTertiaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            fullscreenDialog: false,
                            builder: (_) => const TimerFailsafeScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.timer_outlined),
                      label: const Text('Timer Fail-Safe'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick Trigger availability may vary by device. '
                    'Hardware shortcuts and accessibility flows may be added in a future update.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onTertiaryContainer.withValues(alpha: 0.65),
                      height: 1.35,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
