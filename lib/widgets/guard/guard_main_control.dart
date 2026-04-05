import 'package:flutter/material.dart';

/// Large circular primary control for starting / stopping Guard Mode.
class GuardMainControl extends StatelessWidget {
  const GuardMainControl({
    super.key,
    required this.isListening,
    required this.busy,
    required this.onPressed,
    required this.colorScheme,
  });

  final bool isListening;
  final bool busy;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isListening ? 'Stop Guard Mode' : 'Start Guard Mode';
    final bg = isListening
        ? colorScheme.secondaryContainer
        : colorScheme.primary;
    final fg = isListening
        ? colorScheme.onSecondaryContainer
        : colorScheme.onPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: colorScheme.primary.withValues(alpha: 0.35),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: busy ? null : onPressed,
            child: SizedBox(
              width: 132,
              height: 132,
              child: Center(
                child: busy
                    ? SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: fg,
                        ),
                      )
                    : Icon(
                        isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 52,
                        color: fg,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.92),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
