import 'package:flutter/material.dart';

class GuardQuickActions extends StatelessWidget {
  const GuardQuickActions({
    super.key,
    required this.colorScheme,
    required this.onTestTrigger,
    required this.onTimerFailsafe,
    required this.onQuickTrigger,
    this.testBusy = false,
    this.signInRequired = false,
  });

  final ColorScheme colorScheme;
  final VoidCallback? onTestTrigger;
  final VoidCallback? onTimerFailsafe;
  final VoidCallback? onQuickTrigger;
  final bool testBusy;
  final bool signInRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = signInRequired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniAction(
                icon: Icons.science_outlined,
                label: 'Test trigger',
                busy: testBusy,
                colorScheme: colorScheme,
                onTap: disabled ? null : onTestTrigger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniAction(
                icon: Icons.timer_outlined,
                label: 'Timer fail-safe',
                colorScheme: colorScheme,
                onTap: disabled ? null : onTimerFailsafe,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniAction(
                icon: Icons.bolt_outlined,
                label: 'Quick trigger',
                colorScheme: colorScheme,
                onTap: disabled ? null : onQuickTrigger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.colorScheme,
    this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: colorScheme.surface.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              busy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
