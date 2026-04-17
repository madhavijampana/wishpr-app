import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../config/app_log.dart';

/// Guard Mode speech: [speech_to_text] on Android and iOS (Apple speech APIs on iPhone).
///
/// Callers must obtain microphone permission, then [initialize], then [startListening].
abstract class WishprSpeechListening {
  bool get isAvailable;
  bool get isEngineInitialized;
  bool get userActive;
  bool get isListeningNow;

  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
  });

  Future<void> startListening(SpeechResultListener onResult);

  Future<void> stopListening();

  Future<void> cancel();
}

/// Serialized listen lifecycle. Normal session end uses a *soft* gap (no [cancel]);
/// [cancel] is reserved for user stop / dispose / rare non-spurious [error_client].
class GuardSpeechService implements WishprSpeechListening {
  GuardSpeechService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  SpeechResultListener? _resultListener;
  bool _userActive = false;
  bool _initSucceeded = false;

  String _lastEngineStatus = '';

  /// When the platform last reported [done] — used to ignore trailing [error_client].
  DateTime? _lastDoneAt;

  Timer? _doneDebounceTimer;

  Future<void> _opChain = Future<void>.value();

  @override
  bool get isAvailable => _speech.isAvailable;

  @override
  bool get isEngineInitialized => _initSucceeded;

  @override
  bool get userActive => _userActive;

  @override
  bool get isListeningNow => _speech.isListening;

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Pause after a normal [done] before the next [listen] (no [cancel]).
  static const Duration _softRestartDelay = Duration(milliseconds: 2000);

  /// Hard reset delay after [cancel] (user stop or serious error).
  static const Duration _hardRestartDelay = Duration(milliseconds: 2600);

  static const Duration _doneDebounce = Duration(milliseconds: 500);

  static const Duration _listenForMin = Duration(minutes: 5);
  static const Duration _pauseForMin = Duration(seconds: 12);

  /// Android often emits [error_client] immediately after [done]; treating it as
  /// fatal and calling [cancel] causes a tight error loop.
  static const Duration _errorClientAfterDoneGrace =
      Duration(milliseconds: 1500);

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
  }) async {
    AppLog.d('GuardSpeech: initialize', 'starting');
    try {
      final ok = await _speech.initialize(
        onError: (err) {
          AppLog.w(
            'GuardSpeech: engine onError',
            '${err.errorMsg} permanent=${err.permanent}',
          );
          onError?.call(err);
          _onEngineError(err);
        },
        onStatus: (status) => _handleEngineStatus(status, onStatus),
      );
      _initSucceeded = ok;
      if (ok) {
        AppLog.d(
          'GuardSpeech: initialize',
          'success (isAvailable=${_speech.isAvailable})',
        );
      } else {
        AppLog.w('GuardSpeech: initialize', 'failure — engine returned false');
      }
      return ok;
    } catch (e, st) {
      _initSucceeded = false;
      AppLog.e('GuardSpeech: initialize threw', e, st);
      return false;
    }
  }

  void _onEngineError(SpeechRecognitionError err) {
    if (!_userActive || _resultListener == null) return;
    if (err.errorMsg != 'error_client' || !err.permanent) return;

    final doneAt = _lastDoneAt;
    if (doneAt != null &&
        DateTime.now().difference(doneAt) < _errorClientAfterDoneGrace) {
      AppLog.d(
        'GuardSpeech: ignore error_client',
        'benign tail after done (${DateTime.now().difference(doneAt).inMilliseconds}ms ago)',
      );
      return;
    }

    AppLog.w(
      'GuardSpeech: error_client hard recovery',
      'cancel + ${_hardRestartDelay.inMilliseconds}ms + listen',
    );
    _doneDebounceTimer?.cancel();
    _doneDebounceTimer = null;
    unawaited(
      _enqueueSession(() async {
        if (!_userActive || _resultListener == null) return;
        await _hardTeardown(reason: 'error_client');
        await _invokeListenOnly();
      }),
    );
  }

  void _handleEngineStatus(String status, SpeechStatusListener? out) {
    AppLog.d('GuardSpeech: engine onStatus', status);
    _lastEngineStatus = status;
    out?.call(status);

    if (status == SpeechToText.listeningStatus) {
      _doneDebounceTimer?.cancel();
      _doneDebounceTimer = null;
      return;
    }

    if (!_userActive) return;
    if (status != SpeechToText.doneStatus) return;

    _lastDoneAt = DateTime.now();

    _doneDebounceTimer?.cancel();
    _doneDebounceTimer = Timer(_doneDebounce, () {
      _doneDebounceTimer = null;
      if (!_userActive || _resultListener == null) return;
      if (_cannotStartNewListen()) {
        AppLog.d(
          'GuardSpeech: skip post-done soft restart',
          'isListening=${_speech.isListening} lastStatus=$_lastEngineStatus',
        );
        return;
      }
      AppLog.d(
        'GuardSpeech: post-done soft restart',
        'stop-if-needed + ${_softRestartDelay.inMilliseconds}ms (no cancel)',
      );
      unawaited(
        _enqueueSession(() async {
          if (!_userActive || _resultListener == null) return;
          await _softGapAfterSessionEnd();
          await _invokeListenOnly();
        }),
      );
    });
  }

  bool _cannotStartNewListen() {
    return _speech.isListening ||
        _lastEngineStatus == SpeechToText.listeningStatus;
  }

  void _cancelDoneDebounce() {
    _doneDebounceTimer?.cancel();
    _doneDebounceTimer = null;
  }

  /// Normal cycle: do **not** call [cancel] (often triggers ERROR_CLIENT on next start).
  Future<void> _softGapAfterSessionEnd() async {
    AppLog.d('GuardSpeech: soft gap', 'after session end');
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e, st) {
      AppLog.e('GuardSpeech: soft gap stop', e, st);
    }
    await Future<void>.delayed(_softRestartDelay);
    _lastEngineStatus = '';
    AppLog.d('GuardSpeech: soft gap complete', 'ready for listen');
  }

  /// User stop / serious error: [stop], [cancel], long delay.
  Future<void> _hardTeardown({required String reason}) async {
    AppLog.d(
      'GuardSpeech: hard teardown',
      'reason=$reason → stop → cancel → ${_hardRestartDelay.inMilliseconds}ms',
    );
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e, st) {
      AppLog.e('GuardSpeech: hard teardown stop', e, st);
    }
    try {
      await _speech.cancel();
    } catch (e, st) {
      AppLog.e('GuardSpeech: hard teardown cancel', e, st);
    }
    await Future<void>.delayed(_hardRestartDelay);
    _lastEngineStatus = '';
    AppLog.d('GuardSpeech: hard teardown complete', '');
  }

  Future<void> _enqueueSession(Future<void> Function() work) {
    final run = _opChain.then((_) => work());
    _opChain = run.catchError((Object e, StackTrace st) {
      AppLog.e('GuardSpeech: session chain error', e, st);
    });
    return run;
  }

  Future<void> _invokeListenOnly() async {
    if (!_userActive || !_initSucceeded || _resultListener == null) {
      AppLog.d('GuardSpeech: listen skipped', 'inactive or not initialized');
      return;
    }
    if (!_speech.isAvailable) {
      AppLog.w('GuardSpeech: listen skipped', 'engine not available');
      return;
    }
    if (_cannotStartNewListen()) {
      AppLog.w(
        'GuardSpeech: listen blocked',
        'guard: isListening=${_speech.isListening} lastStatus=$_lastEngineStatus',
      );
      return;
    }

    try {
      AppLog.d(
        'GuardSpeech: listen',
        'listenFor=${_listenForMin.inMinutes}min '
        'pauseFor=${_pauseForMin.inSeconds}s partialResults=true',
      );
      await _speech.listen(
        onResult: _resultListener!,
        listenFor: _listenForMin,
        pauseFor: _pauseForMin,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          onDevice: _android,
          listenMode:
              _android ? ListenMode.dictation : ListenMode.confirmation,
          cancelOnError: false,
        ),
      );
      AppLog.d('GuardSpeech: listen', 'SpeechToText.listen returned');
    } catch (e, st) {
      AppLog.e('GuardSpeech: listen threw', e, st);
    }
  }

  Future<void> _sessionInitialStart() async {
    if (_cannotStartNewListen()) {
      AppLog.d('GuardSpeech: initial start', 'busy — hard teardown');
      await _hardTeardown(reason: 'initial_overlap');
    }
    await _invokeListenOnly();
  }

  @override
  Future<void> startListening(SpeechResultListener onResult) async {
    if (!_initSucceeded) {
      AppLog.w(
        'GuardSpeech: startListening ignored',
        'initialize has not succeeded',
      );
      return;
    }
    _resultListener = onResult;
    _userActive = true;
    _cancelDoneDebounce();
    await _enqueueSession(_sessionInitialStart);
  }

  @override
  Future<void> stopListening() async {
    _userActive = false;
    _resultListener = null;
    _cancelDoneDebounce();
    await _opChain;
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e, st) {
      AppLog.e('GuardSpeech: stopListening stop failed', e, st);
    }
    try {
      await _speech.cancel();
    } catch (e, _) {
      AppLog.w('GuardSpeech: stopListening cancel', '$e');
    }
    _lastEngineStatus = '';
    _lastDoneAt = null;
    AppLog.d('GuardSpeech: stopListening', 'user stopped');
  }

  @override
  Future<void> cancel() async {
    _userActive = false;
    _resultListener = null;
    _cancelDoneDebounce();
    await _opChain;
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (e, st) {
      AppLog.e('GuardSpeech: cancel failed', e, st);
    }
    _lastEngineStatus = '';
    _lastDoneAt = null;
    AppLog.d('GuardSpeech: cancel', 'disposed');
  }
}
