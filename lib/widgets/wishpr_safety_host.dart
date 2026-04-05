import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/app_log.dart';
import '../models/actions/action_execution_result.dart';
import '../models/actions/phrase_action_execution_report.dart';
import '../models/actions/phrase_guard_action.dart';
import '../models/firestore/phrase_document.dart';
import '../services/phrase_action_executor.dart';
import '../services/phrases_repository.dart';
import '../services/quick_trigger_coordinator.dart';
import '../services/quick_trigger_native_channel.dart';
import '../services/safety_prefs.dart';
import '../services/timer_failsafe_controller.dart';
import '../services/timer_failsafe_prefs.dart';
import '../services/trigger_events_repository.dart';
import 'app_scaffold_messenger.dart';
import 'quick_trigger_feedback.dart';

/// Provides [timer] and [quick] to the subtree (Timer Fail-Safe + Quick Trigger).
class WishprSafetyScope extends InheritedWidget {
  const WishprSafetyScope({
    super.key,
    required this.timer,
    required this.quick,
    required super.child,
  });

  final TimerFailsafeController timer;
  final QuickTriggerCoordinator quick;

  static WishprSafetyScope of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<WishprSafetyScope>();
    assert(w != null, 'WishprSafetyScope not found');
    return w!;
  }

  static WishprSafetyScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<WishprSafetyScope>();
  }

  @override
  bool updateShouldNotify(covariant WishprSafetyScope oldWidget) =>
      timer != oldWidget.timer || quick != oldWidget.quick;
}

/// Owns timer + quick-trigger controllers and wires them to the action engine.
class WishprSafetyHost extends StatefulWidget {
  const WishprSafetyHost({super.key, required this.child});

  final Widget child;

  @override
  State<WishprSafetyHost> createState() => _WishprSafetyHostState();
}

class _WishprSafetyHostState extends State<WishprSafetyHost> {
  late final TimerFailsafeController _timer;
  late final QuickTriggerCoordinator _quick;

  final PhrasesRepository _phrasesRepo = PhrasesRepository();
  final TriggerEventsRepository _triggerRepo = TriggerEventsRepository();

  StreamSubscription<User?>? _authSub;

  void _showSafetySnack(String message) {
    final fromContext = mounted ? ScaffoldMessenger.maybeOf(context) : null;
    (fromContext ?? wishprScaffoldMessengerKey.currentState)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _timer = TimerFailsafeController(
      onDeadline: _handleTimerDeadline,
      onPersistArm: (end) async {
        final u = FirebaseAuth.instance.currentUser?.uid;
        if (u != null) await TimerFailsafePrefs.setArmEnd(u, end);
      },
      onPersistClear: () async {
        final u = FirebaseAuth.instance.currentUser?.uid;
        if (u != null) await TimerFailsafePrefs.clear(u);
      },
    );
    _quick = QuickTriggerCoordinator(onFire: _handleQuickTrigger);

    QuickTriggerNativeChannel.channel.setMessageHandler((message) async {
      if (message != null) {
        final r = await _quick.fire();
        showQuickTriggerAttemptFeedback(null, r);
      }
      return null;
    });

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _timer.cancelImSafe();
        _quick.resetAfterSignOut();
      } else {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_restoreTimerIfNeeded()),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_restoreTimerIfNeeded()),
    );
  }

  Future<void> _restoreTimerIfNeeded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_timer.isRunning) return;
    final end = await TimerFailsafePrefs.getArmEnd(uid);
    if (end == null) return;
    final now = DateTime.now();
    if (!end.isAfter(now)) {
      await TimerFailsafePrefs.clear(uid);
      await _handleTimerDeadline();
      return;
    }
    _timer.restoreArmToWallClock(end);
  }

  Future<PhraseDocument?> _resolveSafetyPhrase(String uid) async {
    try {
      final phrases = await _phrasesRepo.fetchPhrasesOnce(uid);
      final active = phrases
          .where((p) => p.active && p.secretPhrase.trim().isNotEmpty)
          .toList();
      if (active.isEmpty) return null;
      final id = await SafetyPrefs.getSafetyPhraseId(uid);
      if (id != null) {
        for (final p in active) {
          if (p.id == id) return p;
        }
      }
      return active.first;
    } catch (e, st) {
      AppLog.e('WishprSafetyHost._resolveSafetyPhrase', e, st);
      return null;
    }
  }

  PhraseActionExecutionReport _failedReport(Object e) {
    return PhraseActionExecutionReport(
      results: [
        ActionExecutionResult(
          action: PhraseGuardAction.sendSms,
          status: 'failed',
          message: 'Wishpr hit an error while running your safety actions.',
          executedAt: DateTime.now().toUtc(),
          detail: {'error': e.toString()},
        ),
      ],
      executionSummary:
          '• Wishpr hit an error while running your safety actions.',
      status: 'Failed',
      locationSnapshot: null,
    );
  }

  Future<void> _handleTimerDeadline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await TimerFailsafePrefs.clear(uid);

    final phrase = await _resolveSafetyPhrase(uid);
    if (phrase == null) {
      AppLog.w('WishprSafetyHost', 'timer expired but no active phrase');
      _showSafetySnack(
        'Timer expired — add an active phrase with safety actions first.',
      );
      return;
    }

    PhraseActionExecutionReport report;
    try {
      report = await PhraseActionExecutor().execute(phrase, uid);
    } catch (e, st) {
      AppLog.e('WishprSafetyHost timer execute', e, st);
      report = _failedReport(e);
    }

    try {
      await _triggerRepo.addPhraseTriggerFromTimer(
        uid: uid,
        phrase: phrase,
        report: report,
      );
    } catch (e, st) {
      AppLog.e('WishprSafetyHost timer Firestore', e, st);
    }

    _showSafetySnack(
      'Timer Fail-Safe triggered — review History for details.',
    );
  }

  Future<void> _handleQuickTrigger() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final phrase = await _resolveSafetyPhrase(uid);
    if (phrase == null) {
      AppLog.w('WishprSafetyHost', 'quick trigger but no active phrase');
      _showSafetySnack(
        'Quick Trigger — add an active phrase with safety actions first.',
      );
      return;
    }

    PhraseActionExecutionReport report;
    try {
      report = await PhraseActionExecutor().execute(phrase, uid);
    } catch (e, st) {
      AppLog.e('WishprSafetyHost quick execute', e, st);
      report = _failedReport(e);
    }

    try {
      await _triggerRepo.addPhraseTriggerFromQuickTrigger(
        uid: uid,
        phrase: phrase,
        report: report,
      );
    } catch (e, st) {
      AppLog.e('WishprSafetyHost quick Firestore', e, st);
    }

    _showSafetySnack('Quick Trigger sent — review History for details.');
  }

  @override
  void dispose() {
    _authSub?.cancel();
    QuickTriggerNativeChannel.channel.setMessageHandler(null);
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WishprSafetyScope(
      timer: _timer,
      quick: _quick,
      child: widget.child,
    );
  }
}
