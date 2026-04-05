import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Foreground countdown for Timer Fail-Safe. Fires [onDeadline] once at zero.
class TimerFailsafeController extends ChangeNotifier {
  TimerFailsafeController({
    required Future<void> Function() onDeadline,
    Future<void> Function(DateTime deadlineEndsAt)? onPersistArm,
    Future<void> Function()? onPersistClear,
  })  : _onDeadline = onDeadline,
        _onPersistArm = onPersistArm,
        _onPersistClear = onPersistClear;

  final Future<void> Function() _onDeadline;
  final Future<void> Function(DateTime deadlineEndsAt)? _onPersistArm;
  final Future<void> Function()? _onPersistClear;

  Timer? _ticker;
  DateTime? _deadline;
  bool _warningPlayed = false;
  bool _handlingDeadline = false;

  bool get isRunning =>
      _deadline != null && DateTime.now().isBefore(_deadline!);

  Duration get remaining {
    if (_deadline == null) return Duration.zero;
    final d = _deadline!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  /// True when ≤30s left and timer has not yet expired.
  bool get inWarningWindow {
    if (_deadline == null) return false;
    final r = _deadline!.difference(DateTime.now());
    return r <= const Duration(seconds: 30) && r > Duration.zero;
  }

  bool get isHandlingDeadline => _handlingDeadline;

  void arm(Duration total) {
    _ticker?.cancel();
    _deadline = DateTime.now().add(total);
    _warningPlayed = false;
    _handlingDeadline = false;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    final persist = _onPersistArm;
    final end = _deadline;
    if (persist != null && end != null) unawaited(persist(end));
    notifyListeners();
    _tick();
  }

  /// Resume countdown after app restart using the same wall-clock end (no new persist).
  void restoreArmToWallClock(DateTime absoluteEnd) {
    if (!absoluteEnd.isAfter(DateTime.now())) return;
    _ticker?.cancel();
    _deadline = absoluteEnd;
    _warningPlayed = false;
    _handlingDeadline = false;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
    _tick();
  }

  void _tick() {
    if (_deadline == null) return;
    final left = _deadline!.difference(DateTime.now());

    if (!_warningPlayed &&
        left <= const Duration(seconds: 30) &&
        left > Duration.zero) {
      _warningPlayed = true;
      HapticFeedback.heavyImpact();
    }

    if (left <= Duration.zero && !_handlingDeadline) {
      _handlingDeadline = true;
      _ticker?.cancel();
      _ticker = null;
      _deadline = null;
      final clear = _onPersistClear;
      if (clear != null) unawaited(clear());
      notifyListeners();
      _onDeadline().whenComplete(() {
        _handlingDeadline = false;
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  /// User cancelled before expiry.
  void cancelImSafe() {
    _ticker?.cancel();
    _ticker = null;
    _deadline = null;
    _warningPlayed = false;
    final clear = _onPersistClear;
    if (clear != null) unawaited(clear());
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
