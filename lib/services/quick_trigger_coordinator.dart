import 'package:flutter/foundation.dart';

/// In-app Quick Trigger path with cooldown. Hardware hooks can be added behind
/// the same [fire] entry point on Android later (accessibility, shortcuts).
abstract final class QuickTriggerPlatformHooks {
  /// Native shortcuts/tiles can send on [QuickTriggerNativeChannel.channelName]
  /// (Dart [BasicMessageChannel]) to invoke the same path as [QuickTriggerCoordinator.fire].
  static bool get volumeHooksAvailable => false;
}

/// Outcome of [QuickTriggerCoordinator.fire] for UX when no action runs.
enum QuickTriggerAttempt {
  fired,
  skippedBusy,
  skippedCooldown,
}

/// Coordinates discreet in-app quick trigger with cooldown to limit accidents.
class QuickTriggerCoordinator extends ChangeNotifier {
  QuickTriggerCoordinator({
    required Future<void> Function() onFire,
    this.cooldown = const Duration(seconds: 25),
  }) : _onFire = onFire;

  final Future<void> Function() _onFire;
  final Duration cooldown;

  DateTime? _lastFire;
  bool _busy = false;

  bool get isBusy => _busy;

  bool get inCooldown {
    if (_lastFire == null) return false;
    return DateTime.now().difference(_lastFire!) < cooldown;
  }

  Duration? get cooldownRemaining {
    if (!inCooldown) return null;
    final left = cooldown - DateTime.now().difference(_lastFire!);
    return left.isNegative ? Duration.zero : left;
  }

  /// Clears cooldown/busy state when the user signs out.
  void resetAfterSignOut() {
    _lastFire = null;
    _busy = false;
    notifyListeners();
  }

  Future<QuickTriggerAttempt> fire() async {
    if (_busy) return QuickTriggerAttempt.skippedBusy;
    if (_lastFire != null &&
        DateTime.now().difference(_lastFire!) < cooldown) {
      return QuickTriggerAttempt.skippedCooldown;
    }
    _busy = true;
    _lastFire = DateTime.now();
    notifyListeners();
    try {
      await _onFire();
      return QuickTriggerAttempt.fired;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
