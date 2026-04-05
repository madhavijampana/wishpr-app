import 'package:speech_to_text/speech_to_text.dart';

/// Wraps [SpeechToText] for Guard Mode: foreground listening only, auto-resumes
/// after each platform session until [stopListening] is called.
class GuardSpeechService {
  GuardSpeechService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  SpeechResultListener? _resultListener;
  bool _userActive = false;
  bool _restartScheduled = false;

  bool get isAvailable => _speech.isAvailable;

  /// Whether the user has started Guard listening (may be between OS sessions).
  bool get userActive => _userActive;

  bool get isListeningNow => _speech.isListening;

  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
  }) async {
    return _speech.initialize(
      onError: onError,
      onStatus: (status) {
        onStatus?.call(status);
        _maybeScheduleResume(status);
      },
    );
  }

  void _maybeScheduleResume(String status) {
    if (!_userActive) return;
    if (status != SpeechToText.doneStatus) return;
    if (_restartScheduled) return;
    _restartScheduled = true;
    Future<void>(() async {
      _restartScheduled = false;
      if (!_userActive) return;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!_userActive) return;
      await _startOneSession();
    });
  }

  /// Starts continuous listening until [stopListening]. [onResult] receives
  /// partial and final updates from the platform.
  Future<void> startListening(SpeechResultListener onResult) async {
    _resultListener = onResult;
    _userActive = true;
    await _startOneSession();
  }

  Future<void> _startOneSession() async {
    if (!_userActive || !_speech.isAvailable || _resultListener == null) {
      return;
    }
    if (_speech.isListening) return;

    try {
      await _speech.listen(
        onResult: _resultListener!,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 12),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
        ),
      );
    } catch (_) {
      // Session failed; [onStatus] may still deliver `done` and schedule retry.
    }
  }

  /// Ends user-requested listening and stops the current session if any.
  Future<void> stopListening() async {
    _userActive = false;
    _resultListener = null;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    _userActive = false;
    _resultListener = null;
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
