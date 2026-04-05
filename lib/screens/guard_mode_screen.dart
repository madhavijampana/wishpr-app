import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../config/app_log.dart';
import '../models/actions/action_execution_result.dart';
import '../models/actions/phrase_action_execution_report.dart';
import '../models/actions/phrase_guard_action.dart';
import '../models/firestore/phrase_document.dart';
import '../models/phrase_matching_mode.dart';
import '../services/current_user_id.dart';
import '../services/firestore_error_message.dart';
import '../services/guard_speech_service.dart';
import '../services/permission_service.dart';
import '../services/phrase_action_executor.dart';
import '../services/phrase_matcher.dart';
import '../services/phrases_repository.dart';
import '../services/trigger_events_repository.dart';
import '../theme/wishpr_constants.dart';
import '../widgets/microphone_permission_dialog.dart';
import '../widgets/wishpr_feedback.dart';

/// Guard Mode card: live speech recognition vs Firestore phrases (foreground only).
class GuardModeScreen extends StatefulWidget {
  const GuardModeScreen({super.key});

  @override
  State<GuardModeScreen> createState() => _GuardModeScreenState();
}

class _GuardModeScreenState extends State<GuardModeScreen> {
  static const PermissionService _permissionService = PermissionService();

  final GuardSpeechService _speech = GuardSpeechService();
  final PhraseTriggerCooldown _cooldown = PhraseTriggerCooldown();

  PhrasesRepository? _phrasesRepoCache;
  TriggerEventsRepository? _triggerRepoCache;

  PhrasesRepository get _phrasesRepo =>
      _phrasesRepoCache ??= PhrasesRepository();

  TriggerEventsRepository get _triggerRepo =>
      _triggerRepoCache ??= TriggerEventsRepository();

  bool _testBusy = false;
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

  /// Shown under live transcription when the silence timer fires (cleared on speech / stop).
  String _silenceUserHint = '';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshMicDebug());
    });
  }

  @override
  void dispose() {
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
      const hint =
          'No speech detected yet. Check the microphone, speak clearly, or tap Stop then Start Listening to retry.';
      setState(() {
        _silenceUserHint = hint;
        _stMatchAttempt = hint;
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
      WishprFeedback.info(
        context,
        'Sign in to load your phrases and use Guard Mode.',
      );
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
        WishprFeedback.error(context, firestoreErrorMessage(e));
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
          setState(() => _speechLastErrorLine = err.errorMsg);
          WishprFeedback.error(
            context,
            'Speech recognition error: ${err.errorMsg}',
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
        setState(() {
          _speechEngineLine = 'Unavailable';
          _stSpeechInit = 'No';
          _stLastException = 'Speech engine initialize() returned false';
        });
        AppLog.w('Guard: speech engine not available');
        WishprFeedback.error(
          context,
          'Speech recognition isn’t available. Check the microphone permission and try again.',
        );
        return;
      }

      setState(() {
        _speechEngineLine = 'Initialized';
        _speechLastErrorLine = '—';
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
        _stMatchAttempt =
            'Cooldown — matched "${matched.label}" but duplicate trigger suppressed.';
      });
      AppLog.d('Guard: cooldown blocks retrigger', matched.id);
      return;
    }

    _cooldown.recordTrigger(matched.id);
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
        setState(() {
          _stActionEngine =
              'Failed — exception during PhraseActionExecutor.execute';
          _stLastException = e.toString();
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
        setState(() {
          _stFirestoreWrite =
              'Failed — ${firestoreErrorMessage(e)}';
          _stLastException = e.toString();
        });
        WishprFeedback.error(context, firestoreErrorMessage(e));
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _stFirestoreWrite = 'Success';
    });
    WishprFeedback.success(
      context,
      'Safety event saved. View details in History.',
    );
    setState(() {
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
          _clearSpeechTrace();
          _stListening = 'No';
        });
      }
    } finally {
      if (mounted) setState(() => _stopBusy = false);
    }
  }

  Future<void> _onTestTrigger() async {
    final uid = currentWishprUid();
    if (uid == null) {
      if (!mounted) return;
      WishprFeedback.info(context, 'Sign in to record a test trigger.');
      return;
    }

    setState(() => _testBusy = true);
    try {
      await _triggerRepo.addSampleTestTrigger(uid);
      if (!mounted) return;
      WishprFeedback.success(
        context,
        'Test trigger saved — open History to review it.',
      );
    } catch (e) {
      if (!mounted) return;
      WishprFeedback.error(context, firestoreErrorMessage(e));
    } finally {
      if (mounted) setState(() => _testBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_moon_rounded,
                  color: cs.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Guard Mode',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Listen for your secret phrases and run your safety playbook automatically.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onPrimaryContainer.withValues(alpha: 0.85),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Diagnostics',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  _DebugLine(
                    label: 'Microphone permission',
                    value: _micDebugLine,
                    theme: theme,
                    cs: cs,
                  ),
                  const SizedBox(height: 8),
                  _DebugLine(
                    label: 'Speech engine',
                    value: _speechEngineLine,
                    theme: theme,
                    cs: cs,
                  ),
                  const SizedBox(height: 8),
                  _DebugLine(
                    label: 'Speech status',
                    value: _speechStatusLine,
                    theme: theme,
                    cs: cs,
                  ),
                  const SizedBox(height: 8),
                  _DebugLine(
                    label: 'Listening (session)',
                    value: _listening
                        ? (_speech.isListeningNow ? 'Active' : 'Between sessions')
                        : 'Off',
                    theme: theme,
                    cs: cs,
                  ),
                  const SizedBox(height: 8),
                  _DebugLine(
                    label: 'Last speech error',
                    value: _speechLastErrorLine,
                    theme: theme,
                    cs: cs,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _refreshMicDebug,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh mic status'),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onPrimaryContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_listening) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          size: 18,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live transcription',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _liveText.isEmpty ? 'Listening… speak your phrase.' : _liveText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.92),
                        height: 1.4,
                      ),
                    ),
                    if (_silenceUserHint.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _silenceUserHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onPrimaryContainer.withValues(alpha: 0.78),
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '$_activePhraseCount active ${_activePhraseCount == 1 ? 'phrase' : 'phrases'} loaded',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Real speech trigger trace',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Step-by-step state for Test Trigger is unchanged; this path is speech only.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.65),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DebugLine(
                      label: '1. Microphone permission granted',
                      value: _stMicGranted,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '2. Speech engine initialized',
                      value: _stSpeechInit,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '3. Listening active',
                      value: _stListening,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '4. Partial transcript (latest partial callback)',
                      value: _stPartialTranscript,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '5. Final transcript (latest final callback)',
                      value: _stFinalTranscript,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '6. Last engine callback',
                      value: _stLastCallbackKind,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '7. Latest recognized text (current utterance)',
                      value: _stLatestRecognized,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '8. Normalized recognized (basic)',
                      value: _stNormalized,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label:
                          '9. Normalized recognized (flexible: collapse repeats)',
                      value: _stNormalizedFlex,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label:
                          '10. Matcher: normalized saved phrase (flex, best)',
                      value: _stMatcherNormPhrase,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '11. Matcher: string similarity score',
                      value: _stMatcherStringSim,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '12. Matcher: token overlap score',
                      value: _stMatcherTokenOverlap,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '13. Matcher: fuzzy keyword score',
                      value: _stMatcherFuzzyKw,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '14. Matcher: final chosen score',
                      value: _stMatcherFinalScore,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '15. Matcher: threshold used',
                      value: _stMatcherThreshold,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '16. Matcher: reason (match / no match)',
                      value: _stMatcherReason,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '17. Phrases loaded from Firestore (count)',
                      value: _stPhraseCount,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '18. Loaded phrase texts',
                      value: _stLoadedPhraseTexts,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '19. Phrase match attempt result',
                      value: _stMatchAttempt,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '20. Matched phrase id · label',
                      value: _stMatchedPhrase,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '21. Action engine execution',
                      value: _stActionEngine,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '22. Firestore trigger_event write',
                      value: _stFirestoreWrite,
                      theme: theme,
                      cs: cs,
                    ),
                    const SizedBox(height: 8),
                    _DebugLine(
                      label: '23. Last exception message',
                      value: _stLastException,
                      theme: theme,
                      cs: cs,
                    ),
                  ],
                ),
              ),
            ],
            if (_matchBanner != null) ...[
              const SizedBox(height: 12),
              Material(
                color: cs.primary.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: cs.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _matchBanner!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_matchFinalStatus != null &&
                              _matchFinalStatus!.isNotEmpty)
                            Chip(
                              label: Text(
                                _matchFinalStatus!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  cs.surface.withValues(alpha: 0.35),
                              side: BorderSide.none,
                              labelStyle: TextStyle(color: cs.primary),
                            ),
                        ],
                      ),
                      if (_matchExecutionSummary != null &&
                          _matchExecutionSummary!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Actions run',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _matchExecutionSummary!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _listening
                  ? FilledButton.tonalIcon(
                      onPressed: _stopBusy ? null : _onStopListening,
                      icon: _stopBusy
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onSecondaryContainer,
                              ),
                            )
                          : const Icon(Icons.stop_rounded, size: 22),
                      label: Text(_stopBusy ? 'Stopping…' : 'Stop Listening'),
                    )
                  : FilledButton.icon(
                      onPressed: _startBusy ? null : _onStartListening,
                      icon: _startBusy
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Icon(Icons.mic_rounded, size: 22),
                      label: Text(_startBusy ? 'Starting…' : 'Start Listening'),
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testBusy ? null : _onTestTrigger,
                icon: _testBusy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : const Icon(Icons.bolt_rounded, size: 20),
                label: Text(_testBusy ? 'Saving…' : 'Test Trigger'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onPrimaryContainer,
                  side: BorderSide(
                    color: cs.primary.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugLine extends StatelessWidget {
  const _DebugLine({
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onPrimaryContainer.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onPrimaryContainer.withValues(alpha: 0.9),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
