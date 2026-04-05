import 'package:flutter/material.dart';

import 'guard_top_state.dart';

class GuardStatusBadge extends StatelessWidget {
  const GuardStatusBadge({
    super.key,
    required this.state,
    required this.colorScheme,
  });

  final GuardTopState state;
  final ColorScheme colorScheme;

  static String labelFor(GuardTopState s) {
    switch (s) {
      case GuardTopState.inactive:
        return 'Inactive';
      case GuardTopState.armed:
        return 'Armed';
      case GuardTopState.listening:
        return 'Listening';
      case GuardTopState.cooldown:
        return 'Cooldown';
      case GuardTopState.triggered:
        return 'Triggered';
    }
  }

  Color _bg(ColorScheme cs) {
    switch (state) {
      case GuardTopState.inactive:
        return cs.surface.withValues(alpha: 0.4);
      case GuardTopState.armed:
        return cs.secondary.withValues(alpha: 0.22);
      case GuardTopState.listening:
        return cs.primary.withValues(alpha: 0.28);
      case GuardTopState.cooldown:
        return cs.tertiary.withValues(alpha: 0.25);
      case GuardTopState.triggered:
        return cs.primary.withValues(alpha: 0.35);
    }
  }

  Color _fg(ColorScheme cs) {
    switch (state) {
      case GuardTopState.inactive:
        return cs.onSurface.withValues(alpha: 0.75);
      case GuardTopState.armed:
        return cs.secondary;
      case GuardTopState.listening:
      case GuardTopState.triggered:
        return cs.primary;
      case GuardTopState.cooldown:
        return cs.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(colorScheme),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _fg(colorScheme).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        labelFor(state),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _fg(colorScheme),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}
