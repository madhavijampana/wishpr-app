import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../config/app_log.dart';
import '../models/actions/action_execution_result.dart';
import '../models/actions/phrase_action_execution_report.dart';
import '../models/actions/phrase_guard_action.dart';
import '../models/firestore/phrase_document.dart';
import '../models/phrase_matching_mode.dart';
import '../services/contacts_repository.dart';
import '../services/current_user_id.dart';
import '../services/debug_mode_controller.dart';
import '../services/firestore_error_message.dart';
import '../services/guard_user_messages.dart';
import '../services/guard_speech_service.dart';
import '../services/permission_service.dart';
import '../services/phrase_action_executor.dart';
import '../services/phrase_matcher.dart';
import '../services/phrases_repository.dart';
import '../services/trigger_events_repository.dart';
import 'timer_failsafe_screen.dart';
import '../theme/wishpr_constants.dart';
import '../widgets/guard/guard_alert_card.dart';
import '../widgets/guard/guard_diagnostics_panel.dart';
import '../widgets/guard/guard_main_control.dart';
import '../widgets/guard/guard_match_success_card.dart';
import '../widgets/guard/guard_quick_actions.dart';
import '../widgets/guard/guard_recording_notice.dart';
import '../widgets/guard/guard_setup_summary_card.dart';
import '../widgets/guard/guard_status_badge.dart';
import '../widgets/guard/guard_status_card.dart';
import '../widgets/guard/guard_top_state.dart';
import '../widgets/quick_trigger_feedback.dart';
import '../widgets/microphone_permission_dialog.dart';
import '../widgets/wishpr_feedback.dart';
import '../widgets/wishpr_safety_host.dart';

/// Guard Mode card: live speech recognition vs Firestore phrases (foreground only).
class GuardModeScreen extends StatefulWidget {
  const GuardModeScreen({super.key});

  @override
  State<GuardModeScreen> createState() => _GuardModeScreenState();
}

class _GuardModeScreenState extends State<GuardModeScreen> {
  static const PermissionService _permissionService = PermissionService();

  final WishprSpeechListening _speech = GuardSpeechService();
  final PhraseTriggerCooldown _cooldown = PhraseTriggerCooldown();

  PhrasesRepository? _phrasesRepoCache;
  TriggerEventsRepository? _triggerRepoCache;
  ContactsRepository? _contactsRepoCache;

  PhrasesRepository get _phrasesRepo =>
      _phrasesRepoCache ??= PhrasesRepository();

  TriggerEventsRepository get _triggerRepo =>
      _triggerRepoCache ??= TriggerEventsRepository();

  ContactsRepository get _contactsRepo =>
      _contactsRepoCache ??= ContactsRepository();

  bool _startBusy = false;
  bool _stopBusy = false;
  bool _listening = false;

  List<PhraseDocument> _phrases = [];
  String _liveText = '';
  String? _matchBanner;
  String? _matchExecutionSummary;
  String? _matchFinalStatus;
  Timer? _matchBannerTimer;
  Timer? _matchDebounceTimer;
  Timer? _silenceTimer;
  DateTime? _lastPhraseFetchAt;

  static const Duration _partialEvalDebounce = Duration(milliseconds: 450);
  static const Duration _silenceNoTranscriptTimeout = Duration(seconds: 5);

  /// Silence / no-transcript hint (friendly copy; also gates user-facing status).
  String _silenceUserHint = '';

  /// User-facing flags (never shown in developer diagnostics text fields).
  bool _friendlyNoMatch = false;
  bool _friendlyCooldown = false;

  int _contactsCount = 0;
  bool _testBusy = false;

  /// Friendly persistent warning below status (no raw errors in normal mode).
  String? _ambientWarning;

  /// Matched phrase had [PhraseDocument.startRecording]; show notice while banner visible.
  bool _lastMatchHadRecordingIntent = false;

  /// Step-by-step trace for the **real** speech → match → persist path.
  String _stMicGranted = '—';
  String _stSpeechInit = '—';
  String _stListening = '—';
  String _stPartialTranscript = '—';
  String _stFinalTranscript = '—';
  String _stLastCallbackKind = '—';
  String _stLatestRecognized = '—';
  String _stNormalized = '—';
  String _stNormalizedFlex = '—';
  String _stMatcherNormPhrase = '—';
  String _stMatcherStringSim = '—';
  String _stMatcherTokenOverlap = '—';
  String _stMatcherFuzzyKw = '—';
  String _stMatcherFinalScore = '—';
  String _stMatcherThreshold = '—';
  String _stMatcherReason = '—';
  String _stPhraseCount = '—';
  String _stLoadedPhraseTexts = '—';
  String _stMatchAttempt = '—';
  String _stMatchedPhrase = '—';
  String _stActionEngine = '—';
  String _stFirestoreWrite = '—';
  String _stLastException = '—';

  /// Diagnostics (permissions + speech engine).
  String _micDebugLine = '—';
  String _speechEngineLine = 'Not initialized';
  String _speechStatusLine = '—';
  String _speechLastErrorLine = '—';

  Future<void> _refreshMicDebug() async {
    final st = await _permissionService.status(WishprPermission.microphone);
    if (!mounted) return;
    setState(() {
      _micDebugLine = _permissionService.statusLabel(st);
    });
  }

  Future<void> _reloadContacts() async {
    final uid = currentWishprUid();
    if (uid == null) {
      if (mounted) setState(() => _contactsCount = 0);
      return;
    }
    try {
      final list = await _contactsRepo.fetchContactsOnceNewestFirst(uid);
      if (!mounted) return;
      setState(() => _contactsCount = list.length);
    } catch (_) {
      if (mounted) setState(() => _contactsCount = 0);
    }
  }

  String _aggregateEnabledActionsSummary() {
    final active = _phrases.where(
      (p) => p.active && p.secretPhrase.trim().isNotEmpty,
    );
    var sms = false;
    var loc = false;
    var call = false;
    var rec = false;
    for (final p in active) {
      if (p.sendSms) sms = true;
      if (p.shareLocation) loc = true;
      if (p.callContact) call = true;
      if (p.startRecording) rec = true;
    }
    final parts = <String>[];
    if (sms) parts.add('SMS');
    if (loc) parts.add('Location');
    if (call) parts.add('Call');
    if (rec) parts.add('Record');
    if (parts.isEmpty) return 'None enabled';
    return parts.join(' · ');
  }

  GuardTopState _computeTopBadgeState() {
    if (_matchBanner != null) return GuardTopState.triggered;
    if (_friendlyCooldown) return GuardTopState.cooldown;
    if (!_listening) return GuardTopState.inactive;
    if (_speech.isListeningNow) return GuardTopState.listening;
    return GuardTopState.armed;
  }

  ({String title, String body}) _statusTitleBody(bool developerMode) {
    if (developerMode) {
      return (
        title: 'Developer mode',
        body:
            'Open Developer Diagnostics below for transcripts, scores, thresholds, and engine data.',
      );
    }
    if (_startBusy) {
      return (title: 'Starting Guard Mode', body: GuardUserMessages.starting);
    }
    if (_stopBusy) {
      return (title: 'Stopping Guard Mode', body: GuardUserMessages.stopping);
    }
    if (_matchBanner != null) {
      return (
        title: 'Trigger matched',
        body:
            'Your safety plan ran. Open History anytime for a full breakdown.',
      );
    }
    if (!_listening) {
      return (
        title: 'Wishpr is inactive',
        body:
            'Wishpr listens for your safety triggers while Guard Mode is active. '
            'Use the button below when you’re ready.',
      );
    }
    if (_silenceUserHint.isNotEmpty) {
      return (
        title: 'Could not hear clearly',
        body: GuardUserMessages.couldNotHearClearly,
      );
    }
    if (_friendlyCooldown) {
      return (
        title: 'Brief pause',
        body: GuardUserMessages.cooldownBriefPause,
      );
    }
    if (_friendlyNoMatch) {
      return (
        title: 'No match yet',
        body: GuardUserMessages.triggerNotMatched,
      );
    }
    if (_listening && !_speech.isListeningNow) {
      return (
        title: 'Wishpr is armed and listening',
        body: 'Reconnecting to the microphone…',
      );
    }
    if (_liveText.trim().isNotEmpty) {
      return (
        title: 'Wishpr is armed and listening',
        body: 'Listening for command phrase',
      );
    }
    return (
      title: 'Wishpr is armed and listening',
      body: 'Listening for wake phrase',
    );
  }

  GuardDiagnosticsSnapshot _diagnosticsSnapshot() {
    return GuardDiagnosticsSnapshot(
      micDebugLine: _micDebugLine,
      speechEngineLine: _speechEngineLine,
      speechStatusLine: _speechStatusLine,
      speechLastErrorLine: _speechLastErrorLine,
      listening: _listening,
      isListeningNow: _speech.isListeningNow,
      liveText: _liveText,
      activePhraseCount: _activePhraseCount,
      stMicGranted: _stMicGranted,
      stSpeechInit: _stSpeechInit,
      stListening: _stListening,
      stPartialTranscript: _stPartialTranscript,
      stFinalTranscript: _stFinalTranscript,
      stLastCallbackKind: _stLastCallbackKind,
      stLatestRecognized: _stLatestRecognized,
      stNormalized: _stNormalized,
      stNormalizedFlex: _stNormalizedFlex,
      stMatcherNormPhrase: _stMatcherNormPhrase,
      stMatcherStringSim: _stMatcherStringSim,
      stMatcherTokenOverlap: _stMatcherTokenOverlap,
      stMatcherFuzzyKw: _stMatcherFuzzyKw,
      stMatcherFinalScore: _stMatcherFinalScore,
      stMatcherThreshold: _stMatcherThreshold,
      stMatcherReason: _stMatcherReason,
      stPhraseCount: _stPhraseCount,
      stLoadedPhraseTexts: _stLoadedPhraseTexts,
      stMatchAttempt: _stMatchAttempt,
      stMatchedPhrase: _stMatchedPhrase,
      stActionEngine: _stActionEngine,
      stFirestoreWrite: _stFirestoreWrite,
      stLastException: _stLastException,
    );
  }

  Future<void> _onTestTrigger() async {
    final uid = currentWishprUid();
    if (uid == null) {
      if (mounted) {
        WishprFeedback.info(context, GuardUserMessages.signInToUse);
      }
      return;
    }
    setState(() => _testBusy = true);
    try {
      await _triggerRepo.addSampleTestTrigger(uid);
      if (!mounted) return;
      WishprFeedback.success(context, 'Test trigger saved. Check History.');
    } catch (e) {
      if (!mounted) return;
      final dev = DebugModeController.instance.value;
      WishprFeedback.error(
        context,
        dev ? firestoreErrorMessage(e) : GuardUserMessages.eventSaveFailed,
      );
    } finally {
      if (mounted) setState(() => _testBusy = false);
    }
  }

  int get _activePhraseCount => _phrases
      .where((p) => p.active && p.secretPhrase.trim().isNotEmpty)
      .length;

  int _activePhraseCountFor(List<PhraseDocument> list) => list
      .where((p) => p.active && p.secretPhrase.trim().isNotEmpty)
      .length;

  /// Full phrase list for trace (ids + secrets + modes).
  static String _formatPhraseTextsTrace(List<PhraseDocument> list) {
    if (list.isEmpty) {
      return '(none — 0 documents from Firestore)';
    }
    final b = StringBuffer();
    for (var i = 0; i < list.length; i++) {
      final p = list[i];
      b.writeln(
        '${i + 1}. id=${p.id} · label="${p.label}" · secret="${p.secretPhrase}" · '
        '${p.matchMode.uiLabel} · active=${p.active}',
      );
    }
    return b.toString().trimRight();
  }

  void _clearSpeechTrace() {
    _stMicGranted = '—';
    _stSpeechInit = '—';
    _stListening = '—';
    _stPartialTranscript = '—';
    _stFinalTranscript = '—';
    _stLastCallbackKind = '—';
    _stLatestRecognized = '—';
    _stNormalized = '—';
    _stNormalizedFlex = '—';
    _stMatcherNormPhrase = '—';
    _stMatcherStringSim = '—';
    _stMatcherTokenOverlap = '—';
    _stMatcherFuzzyKw = '—';
    _stMatcherFinalScore = '—';
    _stMatcherThreshold = '—';
    _stMatcherReason = '—';
    _stPhraseCount = '—';
    _stLoadedPhraseTexts = '—';
    _stMatchAttempt = '—';
    _stMatchedPhrase = '—';
    _stActionEngine = '—';
    _stFirestoreWrite = '—';
    _stLastException = '—';
  }

  void _onDebugModeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    DebugModeController.instance.addListener(_onDebugModeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshMicDebug());
      unawaited(DebugModeController.instance.hydrate(currentWishprUid()));
      unawaited(_reloadContacts());
    });
  }

  @override
  void dispose() {
    DebugModeController.instance.removeListener(_onDebugModeChanged);
    _matchBannerTimer?.cancel();
    _matchDebounceTimer?.cancel();
    _matchDebounceTimer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    unawaited(_speech.cancel());
    super.dispose();
  }

  void _cancelSilenceWatch() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _armSilenceWatch() {
    _cancelSilenceWatch();
    _silenceTimer = Timer(_silenceNoTranscriptTimeout, () {
      if (!mounted || !_listening) return;
      if (_liveText.trim().isNotEmpty) return;
      final dev = DebugModeController.instance.value;
      setState(() {
        _silenceUserHint = GuardUserMessages.couldNotHearClearly;
        _stMatchAttempt = dev
            ? 'SILENCE TIMEOUT: no transcript after '
                '${_silenceNoTranscriptTimeout.inSeconds}s'
            : GuardUserMessages.couldNotHearClearly;
      });
      AppLog.w(
        'Guard: silence timeout — no transcript',
        'after ${_silenceNoTranscriptTimeout.inSeconds}s',
      );
    });
  }

  /// Partial matches only fire when the transcript is a strong enough signal
  /// (substring / near-certain score / exact for strict modes).
  static bool _partialMatchStrongEnough(
    PhraseMatchEvaluation eval,
    PhraseDocument match,
  ) {
    final nPhraseBasic = PhraseMatcher.normalize(match.secretPhrase);
    if (nPhraseBasic.isEmpty) return false;

    switch (match.matchMode) {
      case PhraseMatchingMode.highSecurity:
        final nHeard = eval.normalizedHeard;
        return nHeard == nPhraseBasic;
      case PhraseMatchingMode.exact:
        final nHeard = eval.normalizedHeard;
        if (nHeard == nPhraseBasic) return true;
        if (nPhraseBasic.length >= PhraseMatcher.minPhraseLengthForContains &&
            nHeard.contains(nPhraseBasic)) {
          return true;
        }
        return false;
      case PhraseMatchingMode.flexible:
        final nHeard = eval.normalizedHeardFlexible.isNotEmpty
            ? eval.normalizedHeardFlexible
            : eval.normalizedHeard;
        final nPhrase = PhraseMatcher.normalizeFlexible(match.secretPhrase);
        if (eval.bestScore >= 0.88) return true;
        if (nPhrase.length >= PhraseMatcher.minPhraseLengthForContains &&
            nHeard.contains(nPhrase)) {
          return true;
        }
        return false;
    }
  }

  /// Call inside [setState] alongside other trace updates.
  void _applyEvalToMatcherTrace(PhraseMatchEvaluation eval) {
    _stNormalized =
        eval.normalizedHeard.isEmpty ? '—' : eval.normalizedHeard;
    _stNormalizedFlex = eval.normalizedHeardFlexible.isEmpty
        ? '—'
        : eval.normalizedHeardFlexible;
    final f = eval.flexible;
    if (f != null) {
      _stMatcherNormPhrase =
          f.normalizedPhrase.isEmpty ? '(empty)' : f.normalizedPhrase;
      _stMatcherStringSim = f.stringSimilarity.toStringAsFixed(3);
      _stMatcherTokenOverlap = f.tokenOverlap.toStringAsFixed(3);
      _stMatcherFuzzyKw = f.fuzzyKeywordScore.toStringAsFixed(3);
      _stMatcherFinalScore = f.finalChosenScore.toStringAsFixed(3);
      _stMatcherThreshold = f.threshold.toStringAsFixed(3);
      _stMatcherReason = eval.reason;
    } else {
      final label = eval.bestPhraseLabel;
      _stMatcherNormPhrase = label != null
          ? '— (best "$label" is not Flexible mode)'
          : '—';
      _stMatcherStringSim = '—';
      _stMatcherTokenOverlap = '—';
      _stMatcherFuzzyKw = '—';
      _stMatcherFinalScore =
          eval.bestScore > 0 ? eval.bestScore.toStringAsFixed(3) : '—';
      _stMatcherThreshold = '1.000 (exact / high security)';
      _stMatcherReason = eval.reason;
    }
  }

  void _clearMatcherDiagnosticsLines() {
    _stMatcherNormPhrase = '—';
    _stMatcherStringSim = '—';
    _stMatcherTokenOverlap = '—';
    _stMatcherFuzzyKw = '—';
    _stMatcherFinalScore = '—';
    _stMatcherThreshold = '—';
    _stMatcherReason = '—';
  }

  Future<void> _onStartListening() async {
    final uid = currentWishprUid();
    if (uid == null) {
      if (!mounted) return;
      WishprFeedback.info(context, GuardUserMessages.signInToUse);
      return;
    }

    setState(() => _startBusy = true);
    try {
      await _refreshMicDebug();
      final micStatus =
          await _permissionService.status(WishprPermission.microphone);
      if (!mounted) return;

      if (!_permissionService.isAllowed(micStatus)) {
        setState(() => _stMicGranted = 'No');
        AppLog.w('Guard: microphone not granted');
        await showMicrophonePermissionDialog(
          context: context,
          permissionService: _permissionService,
        );
        return;
      }

      List<PhraseDocument> loaded;
      try {
        loaded = await _phrasesRepo.fetchPhrasesOnce(uid);
      } catch (e) {
        if (!mounted) return;
        final dev = DebugModeController.instance.value;
        setState(() {
          if (!dev) _ambientWarning = GuardUserMessages.phrasesLoadProblem;
        });
        WishprFeedback.error(
          context,
          dev ? firestoreErrorMessage(e) : GuardUserMessages.phrasesLoadProblem,
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _phrases = loaded;
        _clearSpeechTrace();
        _stMicGranted = 'Yes';
        final n = _activePhraseCountFor(loaded);
        _stPhraseCount =
            '${loaded.length} document(s) · $n active with non-empty secret';
        _stLoadedPhraseTexts = _formatPhraseTextsTrace(loaded);
        _stMatchAttempt =
            'Idle — will match on partial and final transcripts (debounced).';
      });

      AppLog.d(
        'Guard: phrases loaded at session start',
        'count=${loaded.length}',
      );

      unawaited(_reloadContacts());

      if (_activePhraseCount == 0) {
        WishprFeedback.info(
          context,
          'Add at least one active secret phrase to detect speech triggers.',
        );
      }

      final speechOk = await _speech.initialize(
        onError: (err) {
          AppLog.w(
            'Guard: speech onError',
            '${err.errorMsg} permanent=${err.permanent}',
          );
          if (!mounted) return;
          final dev = DebugModeController.instance.value;
          setState(() {
            _speechLastErrorLine = err.errorMsg;
            if (!dev) {
              _ambientWarning = GuardUserMessages.speechRecognitionProblem;
            }
          });
          WishprFeedback.error(
            context,
            dev
                ? 'Speech error: ${err.errorMsg}'
                : GuardUserMessages.speechRecognitionProblem,
          );
        },
        onStatus: (status) {
          AppLog.d('Guard: speech onStatus', status);
          if (!mounted) return;
          setState(() => _speechStatusLine = status);
        },
      );

      if (!mounted) return;
      if (!speechOk) {
        final dev = DebugModeController.instance.value;
        setState(() {
          _speechEngineLine = 'Unavailable';
          _stSpeechInit = 'No';
          _stLastException = 'Speech engine initialize() returned false';
          if (!dev) {
            _ambientWarning = GuardUserMessages.speechEngineUnavailable;
          }
        });
        AppLog.w('Guard: speech engine not available');
        WishprFeedback.error(
          context,
          GuardUserMessages.speechEngineUnavailable,
        );
        return;
      }

      setState(() {
        _speechEngineLine = 'Initialized';
        _speechLastErrorLine = '—';
        _ambientWarning = null;
        _listening = true;
        _liveText = '';
        _silenceUserHint = '';
        _matchBanner = null;
        _matchExecutionSummary = null;
        _matchFinalStatus = null;
        _stSpeechInit = 'Yes';
        _stListening = 'Yes (Guard Mode on)';
        _stPartialTranscript = '—';
        _stFinalTranscript = '—';
        _stLastCallbackKind = '—';
        _stLatestRecognized = '—';
        _stNormalized = '—';
        _stNormalizedFlex = '—';
        _stMatcherNormPhrase = '—';
        _stMatcherStringSim = '—';
        _stMatcherTokenOverlap = '—';
        _stMatcherFuzzyKw = '—';
        _stMatcherFinalScore = '—';
        _stMatcherThreshold = '—';
        _stMatcherReason = '—';
        _stMatchAttempt =
            'Listening — partial + final matching (debounced); strong partials can trigger.';
        _stMatchedPhrase = '—';
        _stActionEngine = '—';
        _stFirestoreWrite = '—';
        _stLastException = '—';
      });

      AppLog.d('Guard: startListening invoked');
      _lastPhraseFetchAt = DateTime.now();
      _armSilenceWatch();
      await _speech.startListening(_onSpeechResult);
    } finally {
      if (mounted) setState(() => _startBusy = false);
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    final words = result.recognizedWords;
    final isFinal = result.finalResult;

    AppLog.d(
      'Guard: onResult',
      'recognizedWords="$words" finalResult=$isFinal',
    );

    final uid = currentWishprUid();

      setState(() {
        _liveText = words;
        _friendlyNoMatch = false;
        _friendlyCooldown = false;
        if (_ambientWarning != null) _ambientWarning = null;
        _stLastCallbackKind = isFinal ? 'final' : 'partial';
      if (!isFinal) {
        _stPartialTranscript =
            words.isEmpty ? '(empty partial)' : words;
      } else {
        _stFinalTranscript = words.isEmpty ? '(empty final)' : words;
      }
      _stLatestRecognized = words.isEmpty ? '(empty)' : words;
      _stNormalized = PhraseMatcher.normalize(words);
      _stNormalizedFlex = PhraseMatcher.normalizeFlexible(words);
      _stListening =
          'Yes (session active=${_speech.isListeningNow}, '
          '${isFinal ? 'FINAL' : 'partial'} callback)';
      if (words.trim().isEmpty) {
        _stMatchAttempt =
            'Empty ${isFinal ? "final" : "partial"} — speak your phrase.';
      } else {
        if (_silenceUserHint.isNotEmpty) _silenceUserHint = '';
        _stMatchAttempt = isFinal
            ? 'Evaluating (final, immediate)…'
            : 'Evaluating (partial, debounced ${_partialEvalDebounce.inMilliseconds}ms)…';
      }
    });

    if (words.trim().isNotEmpty) {
      _cancelSilenceWatch();
    }

    if (uid == null) return;

    _matchDebounceTimer?.cancel();
    final delay = isFinal ? Duration.zero : _partialEvalDebounce;
    _matchDebounceTimer = Timer(delay, () {
      if (!mounted) return;
      unawaited(_evaluateAndMaybeTrigger(uid, words, isFinal));
    });
  }

  Future<void> _evaluateAndMaybeTrigger(
    String uid,
    String heardWords,
    bool isFinal,
  ) async {
    if (!mounted) return;

    final trimmed = heardWords.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _stLatestRecognized = '(empty)';
        _stNormalized = '(empty)';
        _stNormalizedFlex = '(empty)';
        _clearMatcherDiagnosticsLines();
        _stMatchAttempt = isFinal
            ? 'Skipped match — empty final transcript.'
            : 'Skipped match — empty partial transcript.';
      });
      AppLog.d('Guard: onResult eval skipped — empty words', 'final=$isFinal');
      return;
    }

    final normalizedPreview = PhraseMatcher.normalize(trimmed);
    if (normalizedPreview.isEmpty) {
      if (!mounted) return;
      setState(() {
        _stNormalized = '(empty after normalization)';
        _stNormalizedFlex = '(empty)';
        _clearMatcherDiagnosticsLines();
        _stMatchAttempt =
            'BLOCKED: Transcript normalizes to empty (whitespace/punctuation only).';
      });
      AppLog.w('Guard: match blocked — normalized empty');
      return;
    }

    setState(() {
      _stMatchAttempt = isFinal
          ? 'Fetching phrases (final)…'
          : 'Fetching phrases (partial, throttled)…';
      _stFirestoreWrite = '—';
      _stActionEngine = '—';
      _stMatchedPhrase = '—';
    });

    final now = DateTime.now();
    final shouldRefresh = isFinal ||
        _lastPhraseFetchAt == null ||
        now.difference(_lastPhraseFetchAt!) >
            const Duration(seconds: 2);

    List<PhraseDocument> fresh;
    var fetchOk = false;
    Object? fetchError;

    if (shouldRefresh) {
      try {
        fresh = await _phrasesRepo.fetchPhrasesOnce(uid);
        fetchOk = true;
        _lastPhraseFetchAt = now;
        AppLog.d('Guard: phrases fetched', 'count=${fresh.length} final=$isFinal');
      } catch (e, st) {
        fetchError = e;
        AppLog.e('Guard: phrases fetch failed — using cache if any', e, st);
        fresh = List<PhraseDocument>.from(_phrases);
      }
    } else {
      fresh = List<PhraseDocument>.from(_phrases);
      fetchOk = true;
      AppLog.d(
        'Guard: phrase fetch skipped (throttle)',
        'using cache count=${fresh.length}',
      );
    }

    if (!mounted) return;

    if (fetchOk && fetchError == null) {
      setState(() => _stLastException = '—');
    } else if (fresh.isNotEmpty && fetchError != null) {
      setState(() {
        _stLastException =
            'Phrase refresh failed (using cache): $fetchError';
      });
    }

    if (!fetchOk && fresh.isEmpty) {
      setState(() {
        _stPhraseCount = '0';
        _stLoadedPhraseTexts = '(none)';
        _stMatchAttempt =
            'BLOCKED: Firestore fetch failed and no cached phrases — cannot match.';
        _stLastException = fetchError?.toString() ?? 'unknown';
      });
      AppLog.w('Guard: match blocked — no phrases after failed fetch');
      return;
    }

    if (fetchOk && fresh.isEmpty) {
      setState(() {
        _phrases = fresh;
        _stPhraseCount = '0 documents, 0 active with secret';
        _stLoadedPhraseTexts = _formatPhraseTextsTrace(fresh);
        _stMatchAttempt =
            'BLOCKED: No phrases loaded from Firestore (0 documents).';
      });
      AppLog.w('Guard: match blocked — zero phrase documents');
      return;
    }

    setState(() {
      _phrases = fresh;
      final activeN = _activePhraseCountFor(fresh);
      _stPhraseCount =
          '${fresh.length} document(s) · $activeN active with non-empty secret';
      _stLoadedPhraseTexts = _formatPhraseTextsTrace(fresh);
      _stMatchAttempt = 'Normalizing & running matcher…';
    });

    AppLog.d('Guard: normalization completed', '"$normalizedPreview" final=$isFinal');

    final eval = PhraseMatcher.evaluate(trimmed, fresh);
    if (!mounted) return;

    PhraseDocument? candidate = eval.match;
    if (candidate != null && !isFinal) {
      if (!_partialMatchStrongEnough(eval, candidate)) {
        setState(() {
          _applyEvalToMatcherTrace(eval);
          _friendlyNoMatch = false;
          _stMatchAttempt =
              'Partial: no strong match yet — ${eval.reason} '
              '(need phrase substring, high score, or exact for strict mode).';
        });
        AppLog.d(
          'Guard: partial match suppressed (not strong enough)',
          eval.reason,
        );
        return;
      }
    }

    setState(() {
      _applyEvalToMatcherTrace(eval);
      _stMatchAttempt = candidate != null
          ? 'Match OK (${isFinal ? "final" : "partial"}) — ${eval.reason}'
          : 'No match — ${eval.reason}';
      _friendlyNoMatch = candidate == null && trimmed.isNotEmpty;
      if (candidate != null) _friendlyCooldown = false;
    });
    AppLog.d('Guard: match decision', '${eval.reason} final=$isFinal');

    if (candidate == null) {
      return;
    }

    final matched = candidate;

    setState(() {
      _stMatchedPhrase = 'id=${matched.id} · label="${matched.label}"';
    });

    if (!_cooldown.canTrigger(matched.id)) {
      if (!mounted) return;
      setState(() {
        _friendlyCooldown = true;
        _friendlyNoMatch = false;
        _stMatchAttempt =
            'Cooldown — matched "${matched.label}" but duplicate trigger suppressed.';
      });
      AppLog.d('Guard: cooldown blocks retrigger', matched.id);
      return;
    }

    _cooldown.recordTrigger(matched.id);
    if (mounted) {
      setState(() {
        _friendlyNoMatch = false;
        _friendlyCooldown = false;
      });
    }
    await _persistTrigger(uid, matched, trimmed);
  }

  Future<void> _persistTrigger(
    String uid,
    PhraseDocument phrase,
    String recognizedSpeech,
  ) async {
    if (!mounted) return;
    setState(() {
      _stActionEngine = 'Running…';
      _stFirestoreWrite = '—';
    });
    AppLog.d('Guard: action engine execution starting', phrase.id);

    PhraseActionExecutionReport report;
    try {
      report = await PhraseActionExecutor().execute(phrase, uid);
      if (!mounted) return;
      final failed = report.status == 'Failed' || report.status == 'Partial';
      setState(() {
        _stActionEngine = failed
            ? 'Completed with issues — status=${report.status}'
            : 'Success — status=${report.status}';
      });
      AppLog.d('Guard: action engine execution finished', report.status);
    } catch (e, st) {
      AppLog.e('Guard: action engine execution threw', e, st);
      if (mounted) {
        final dev = DebugModeController.instance.value;
        setState(() {
          _stActionEngine =
              'Failed — exception during PhraseActionExecutor.execute';
          _stLastException = e.toString();
          if (!dev) {
            _ambientWarning =
                'Wishpr couldn’t finish every safety step. Check History for details.';
          }
        });
      }
      report = PhraseActionExecutionReport(
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

    if (!mounted) return;
    setState(() {
      _stFirestoreWrite = 'Attempting write to trigger_events…';
    });
    AppLog.d('Guard: Firestore trigger_event write attempted', phrase.id);

    try {
      await _triggerRepo.addPhraseTriggerFromSpeech(
        uid: uid,
        phrase: phrase,
        report: report,
        recognizedSpeech: recognizedSpeech,
      );
      AppLog.d('Guard: Firestore trigger_event write success', phrase.id);
    } catch (e, st) {
      AppLog.e('Guard: Firestore trigger_event write failed', e, st);
      if (mounted) {
        final dev = DebugModeController.instance.value;
        setState(() {
          _stFirestoreWrite = 'Failed — ${firestoreErrorMessage(e)}';
          _stLastException = e.toString();
          if (!dev) _ambientWarning = GuardUserMessages.eventSaveFailed;
        });
        WishprFeedback.error(
          context,
          dev ? firestoreErrorMessage(e) : GuardUserMessages.eventSaveFailed,
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _stFirestoreWrite = 'Success';
      _friendlyNoMatch = false;
      _friendlyCooldown = false;
    });
    WishprFeedback.success(
      context,
      'Safety event saved. View details in History.',
    );
    setState(() {
      _lastMatchHadRecordingIntent = phrase.startRecording;
      _matchBanner = 'Phrase matched: ${phrase.label}';
      _matchExecutionSummary = report.executionSummary;
      _matchFinalStatus = report.status;
    });
    _matchBannerTimer?.cancel();
    _matchBannerTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _matchBanner = null;
          _matchExecutionSummary = null;
          _matchFinalStatus = null;
          _lastMatchHadRecordingIntent = false;
        });
      }
    });
  }

  Future<void> _onStopListening() async {
    setState(() => _stopBusy = true);
    try {
      _matchDebounceTimer?.cancel();
      _matchDebounceTimer = null;
      _cancelSilenceWatch();
      await _speech.stopListening();
      if (mounted) {
        setState(() {
          _listening = false;
          _liveText = '';
          _silenceUserHint = '';
          _friendlyNoMatch = false;
          _friendlyCooldown = false;
          _ambientWarning = null;
          _clearSpeechTrace();
          _stListening = 'No';
        });
      }
    } finally {
      if (mounted) setState(() => _stopBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final developerMode = DebugModeController.instance.value;
    final safety = WishprSafetyScope.maybeOf(context);
    final status = _statusTitleBody(developerMode);
    final signedIn = currentWishprUid() != null;

    return ListenableBuilder(
      listenable: Listenable.merge([
        DebugModeController.instance,
        if (safety != null) safety.timer,
      ]),
      builder: (context, _) {
        final timerRunning = safety?.timer.isRunning ?? false;
        final badge = _computeTopBadgeState();
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WishprLayout.guardCardRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primaryContainer,
                cs.secondaryContainer.withValues(alpha: 0.55),
              ],
            ),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_moon_rounded,
                        color: cs.primary,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guard Mode',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Wishpr listens for your safety triggers while '
                              'Guard Mode is active.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onPrimaryContainer
                                    .withValues(alpha: 0.82),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GuardStatusBadge(state: badge, colorScheme: cs),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Semantics(
                      button: true,
                      label: _listening
                          ? 'Stop Guard Mode'
                          : 'Start Guard Mode',
                      child: GuardMainControl(
                        isListening: _listening,
                        busy: _listening ? _stopBusy : _startBusy,
                        onPressed: _listening
                            ? _onStopListening
                            : _onStartListening,
                        colorScheme: cs,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GuardStatusCard(
                    title: status.title,
                    body: status.body,
                    colorScheme: cs,
                  ),
                  if (_ambientWarning != null &&
                      _ambientWarning!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    GuardAlertCard(
                      message: _ambientWarning!,
                      colorScheme: cs,
                    ),
                  ],
                  if (_matchBanner != null) ...[
                    const SizedBox(height: 16),
                    GuardMatchSuccessCard(
                      developerMode: developerMode,
                      bannerLine: _matchBanner!,
                      executionSummary: _matchExecutionSummary,
                      finalStatus: _matchFinalStatus,
                      colorScheme: cs,
                    ),
                  ],
                  if (_lastMatchHadRecordingIntent &&
                      _matchBanner != null &&
                      !developerMode) ...[
                    const SizedBox(height: 12),
                    GuardRecordingNotice(colorScheme: cs),
                  ],
                  const SizedBox(height: 22),
                  GuardSetupSummaryCard(
                    activePhrases: _activePhraseCount,
                    trustedContacts: _contactsCount,
                    actionsSummary: _aggregateEnabledActionsSummary(),
                    timerFailsafeActive: timerRunning,
                    colorScheme: cs,
                  ),
                  const SizedBox(height: 22),
                  GuardQuickActions(
                    colorScheme: cs,
                    testBusy: _testBusy,
                    signInRequired: !signedIn,
                    onTestTrigger: _onTestTrigger,
                    onTimerFailsafe: signedIn
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const TimerFailsafeScreen(),
                              ),
                            );
                          }
                        : null,
                    onQuickTrigger: signedIn && safety != null
                        ? () async {
                            final r = await safety.quick.fire();
                            if (!context.mounted) return;
                            showQuickTriggerAttemptFeedback(context, r);
                          }
                        : null,
                  ),
                  if (developerMode) ...[
                    const SizedBox(height: 20),
                    GuardDiagnosticsPanel(
                      theme: theme,
                      colorScheme: cs,
                      data: _diagnosticsSnapshot(),
                      onRefreshMic: _refreshMicDebug,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
