import 'dart:math' as math;

import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';

import '../config/app_log.dart';
import '../models/firestore/phrase_document.dart';
import '../models/phrase_matching_mode.dart';

/// Debug metrics for Flexible mode (Guard panel + logs).
class FlexibleMatchDiagnostics {
  const FlexibleMatchDiagnostics({
    required this.normalizedPhrase,
    required this.normalizedHeard,
    required this.stringSimilarity,
    required this.tokenOverlap,
    required this.fuzzyKeywordScore,
    required this.finalChosenScore,
    required this.threshold,
    required this.componentsSummary,
  });

  final String normalizedPhrase;
  final String normalizedHeard;
  final double stringSimilarity;
  final double tokenOverlap;
  final double fuzzyKeywordScore;
  final double finalChosenScore;
  final double threshold;
  final String componentsSummary;
}

/// Result of comparing heard speech to saved phrases (UI + Guard debug).
class PhraseMatchEvaluation {
  const PhraseMatchEvaluation({
    required this.match,
    required this.reason,
    required this.normalizedHeard,
    this.normalizedHeardFlexible = '',
    this.bestScore = 0,
    this.bestPhraseLabel,
    this.flexible,
  });

  final PhraseDocument? match;
  final String reason;
  /// Basic normalization (lowercase, trim, punctuation, spaces) — used for exact / high security.
  final String normalizedHeard;
  /// Repetition-collapsed normalization of heard text (Flexible pipeline).
  final String normalizedHeardFlexible;
  final double bestScore;
  final String? bestPhraseLabel;
  /// Populated when the highest-scoring candidate phrase uses Flexible mode.
  final FlexibleMatchDiagnostics? flexible;
}

/// Normalization and matching for spoken text vs [PhraseDocument.secretPhrase].
/// Each phrase uses its own [PhraseDocument.matchMode].
abstract final class PhraseMatcher {
  /// Flexible mode: baseline threshold for longer phrases (phrase-length-aware tuning below).
  static const double flexibleThreshold = 0.72;

  static const int minPhraseLengthForContains = 3;

  /// Lowercase, trim, diacritic fold, collapse whitespace, strip punctuation.
  static String normalize(String input) {
    final lower = removeDiacritics(input.toLowerCase().trim());
    final collapsed = lower.replaceAll(RegExp(r'\s+'), ' ');
    return collapsed.replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  /// Normalization for Flexible mode only: [normalize] plus repetition collapse.
  static String normalizeFlexible(String input) {
    return _collapseRepetitions(normalize(input));
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Collapses consecutive duplicate tokens and repeated full word sequences
  /// (e.g. `hi mano hi mano` → `hi mano`).
  static String _collapseRepetitions(String normalized) {
    var words = normalized
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';

    final once = <String>[];
    for (final w in words) {
      if (once.isEmpty || once.last != w) once.add(w);
    }
    words = once;

    while (words.length >= 2) {
      if (words.length.isOdd) break;
      final mid = words.length ~/ 2;
      final a = words.sublist(0, mid);
      final b = words.sublist(mid);
      if (_listEq(a, b)) {
        words = List<String>.from(a);
      } else {
        break;
      }
    }
    return words.join(' ');
  }

  static List<String> _tokensList(String normalized) {
    if (normalized.isEmpty) return [];
    return normalized
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Jaccard on unique tokens (exact string match per token).
  static double _exactTokenJaccard(List<String> heard, List<String> phrase) {
    if (phrase.isEmpty) return 0;
    final hs = heard.toSet();
    final ps = phrase.toSet();
    final inter = ps.where(hs.contains).length;
    final union = hs.length + ps.length - inter;
    return union > 0 ? inter / union : 0.0;
  }

  /// Subset-style overlap: share of phrase tokens that appear exactly in heard.
  static double _exactTokenOverlapRatio(List<String> heard, List<String> phrase) {
    if (phrase.isEmpty) return 0;
    final hs = heard.toSet();
    var hit = 0;
    for (final t in phrase) {
      if (hs.contains(t)) hit++;
    }
    return hit / phrase.length;
  }

  /// Lightweight fuzzy similarity between two single tokens (spoken variation).
  static double _tokenFuzzySimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;

    final maxLen = math.max(a.length, b.length);
    final d = levenshtein(a, b);
    var ratio = 1.0 - d / maxLen;

    if (maxLen <= 2) {
      if (d <= 1) ratio = math.max(ratio, 0.88);
    } else if (maxLen <= 4) {
      if (d <= 1) ratio = math.max(ratio, 0.86);
    } else {
      if (d <= 2 && d / maxLen <= 0.25) {
        ratio = math.max(ratio, 0.84);
      }
    }
    return ratio.clamp(0.0, 1.0);
  }

  /// Average over phrase tokens of (best fuzzy match to any heard token).
  static double _fuzzyKeywordCoverage(
    List<String> heardTokens,
    List<String> phraseTokens,
  ) {
    if (phraseTokens.isEmpty) return 0;
    var sum = 0.0;
    for (final p in phraseTokens) {
      var best = 0.0;
      for (final h in heardTokens) {
        final s = _tokenFuzzySimilarity(p, h);
        if (s > best) best = s;
      }
      sum += best;
    }
    return sum / phraseTokens.length;
  }

  static double _similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 1.0;
    final d = levenshtein(a, b);
    return 1.0 - d / maxLen;
  }

  static double _flexibleThresholdForPhrase(String nPhraseFlex) {
    final tokens = _tokensList(nPhraseFlex);
    final n = tokens.length;
    final len = nPhraseFlex.length;
    if (n <= 2 || len <= 14) return 0.55;
    if (n <= 4) return 0.64;
    return flexibleThreshold;
  }

  static ({double score, FlexibleMatchDiagnostics diagnostics}) _flexibleScoreDetailed(
    String nHeard,
    String nPhrase,
  ) {
    if (nPhrase.isEmpty || nHeard.isEmpty) {
      const z = 0.0;
      return (
        score: z,
        diagnostics: FlexibleMatchDiagnostics(
          normalizedPhrase: nPhrase,
          normalizedHeard: nHeard,
          stringSimilarity: z,
          tokenOverlap: z,
          fuzzyKeywordScore: z,
          finalChosenScore: z,
          threshold: _flexibleThresholdForPhrase(nPhrase),
          componentsSummary: 'empty input',
        ),
      );
    }

    final ht = _tokensList(nHeard);
    final pt = _tokensList(nPhrase);

    final stringSim = _similarity(nHeard, nPhrase);
    final jaccard = _exactTokenJaccard(ht, pt);
    final subsetOverlap = _exactTokenOverlapRatio(ht, pt);
    final tokenOverlapSignal = math.max(jaccard, subsetOverlap);
    final fuzzyKw = _fuzzyKeywordCoverage(ht, pt);

    var substringBoost = 0.0;
    if (nPhrase.length >= minPhraseLengthForContains &&
        nHeard.contains(nPhrase)) {
      substringBoost = 0.96;
    }

    final chosen = math.max(
      math.max(math.max(stringSim, tokenOverlapSignal), fuzzyKw),
      substringBoost,
    );

    final threshold = _flexibleThresholdForPhrase(nPhrase);
    final summary =
        'max(string=${stringSim.toStringAsFixed(2)}, '
        'tokenOverlap=${tokenOverlapSignal.toStringAsFixed(2)}, '
        'fuzzy=${fuzzyKw.toStringAsFixed(2)}'
        '${substringBoost > 0 ? ', substring=${substringBoost.toStringAsFixed(2)}' : ''}) '
        '→ ${chosen.toStringAsFixed(2)} vs threshold ${threshold.toStringAsFixed(2)}';

    return (
      score: chosen,
      diagnostics: FlexibleMatchDiagnostics(
        normalizedPhrase: nPhrase,
        normalizedHeard: nHeard,
        stringSimilarity: stringSim,
        tokenOverlap: tokenOverlapSignal,
        fuzzyKeywordScore: fuzzyKw,
        finalChosenScore: chosen,
        threshold: threshold,
        componentsSummary: summary,
      ),
    );
  }

  static double _flexibleScore(String nHeard, String nPhrase) {
    return _flexibleScoreDetailed(nHeard, nPhrase).score;
  }

  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final row0 = List<int>.generate(b.length + 1, (i) => i);
    final row1 = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      row1[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        row1[j + 1] = _min3(
          row1[j] + 1,
          row0[j + 1] + 1,
          row0[j] + cost,
        );
      }
      for (var j = 0; j <= b.length; j++) {
        row0[j] = row1[j];
      }
    }
    return row0[b.length];
  }

  static int _min3(int a, int b, int c) {
    var m = a;
    if (b < m) m = b;
    if (c < m) m = c;
    return m;
  }

  /// [exact]: normalized equal OR full phrase substring in heard (basic normalize only).
  static double _exactModeScore(String nHeard, String nPhrase) {
    if (nPhrase.isEmpty) return 0;
    if (nHeard == nPhrase) return 1.0;
    if (nPhrase.length >= minPhraseLengthForContains &&
        nHeard.contains(nPhrase)) {
      return 1.0;
    }
    return 0;
  }

  /// [highSecurity]: normalized equality only (basic normalize).
  static double _highSecurityScore(String nHeard, String nPhrase) {
    if (nPhrase.isEmpty) return 0;
    return nHeard == nPhrase ? 1.0 : 0.0;
  }

  static double _scoreForMode(
    String nHeardBasic,
    String nPhraseBasic,
    String nHeardFlex,
    String nPhraseFlex,
    PhraseMatchingMode mode,
  ) {
    switch (mode) {
      case PhraseMatchingMode.flexible:
        return _flexibleScore(nHeardFlex, nPhraseFlex);
      case PhraseMatchingMode.exact:
        return _exactModeScore(nHeardBasic, nPhraseBasic);
      case PhraseMatchingMode.highSecurity:
        return _highSecurityScore(nHeardBasic, nPhraseBasic);
    }
  }

  static double _thresholdForPhrase(PhraseDocument p, String nPhraseFlex) {
    switch (p.matchMode) {
      case PhraseMatchingMode.flexible:
        return _flexibleThresholdForPhrase(nPhraseFlex);
      case PhraseMatchingMode.exact:
      case PhraseMatchingMode.highSecurity:
        return 1.0;
    }
  }

  /// Human-readable summary of configured actions (History cards).
  static String buildActionSummary(PhraseDocument phrase) {
    final parts = <String>[];
    if (phrase.sendSms) parts.add('SMS');
    if (phrase.shareLocation) parts.add('Location');
    if (phrase.callContact) parts.add('Call');
    if (phrase.startRecording) parts.add('Record');
    if (parts.isEmpty) return 'No actions';
    return parts.join(' + ');
  }

  static PhraseDocument? findMatch(
    String heard,
    Iterable<PhraseDocument> phrases,
  ) {
    return evaluate(heard, phrases).match;
  }

  static PhraseMatchEvaluation evaluate(
    String heard,
    Iterable<PhraseDocument> phrases,
  ) {
    final nHeardBasic = normalize(heard);
    if (kDebugMode) {
      AppLog.d(
        'PhraseMatcher.normalize',
        'rawLen=${heard.length} → basic="$nHeardBasic" '
        'flex="${normalizeFlexible(heard)}"',
      );
    }
    if (nHeardBasic.isEmpty) {
      if (kDebugMode) {
        AppLog.d('PhraseMatcher.matchDecision', 'no match — normalized empty');
      }
      return const PhraseMatchEvaluation(
        match: null,
        reason: 'No match: recognized text is empty after normalization.',
        normalizedHeard: '',
        normalizedHeardFlexible: '',
      );
    }

    final nHeardFlex = normalizeFlexible(heard);

    final list = phrases.toList();
    final activeWithPhrase = list
        .where((p) => p.active && normalize(p.secretPhrase).isNotEmpty)
        .toList();
    if (activeWithPhrase.isEmpty) {
      if (kDebugMode) {
        AppLog.d(
          'PhraseMatcher.matchDecision',
          'no match — 0 active phrases with secret (${list.length} docs loaded)',
        );
      }
      return PhraseMatchEvaluation(
        match: null,
        reason:
            'No match: no active phrases with non-empty secret text (${list.length} loaded).',
        normalizedHeard: nHeardBasic,
        normalizedHeardFlexible: nHeardFlex,
      );
    }

    PhraseDocument? topPhrase;
    var top = 0.0;
    String? topLabel;
    FlexibleMatchDiagnostics? flexDiag;

    for (final p in activeWithPhrase) {
      final nPhraseBasic = normalize(p.secretPhrase);
      final nPhraseFlex = normalizeFlexible(p.secretPhrase);
      final score = _scoreForMode(
        nHeardBasic,
        nPhraseBasic,
        nHeardFlex,
        nPhraseFlex,
        p.matchMode,
      );
      if (score > top) {
        top = score;
        topPhrase = p;
        topLabel = p.label.isNotEmpty ? p.label : p.secretPhrase;
        if (p.matchMode == PhraseMatchingMode.flexible) {
          flexDiag = _flexibleScoreDetailed(nHeardFlex, nPhraseFlex).diagnostics;
        } else {
          flexDiag = null;
        }
      }
    }

    final threshold = topPhrase != null
        ? _thresholdForPhrase(topPhrase, normalizeFlexible(topPhrase.secretPhrase))
        : 1.0;

    if (topPhrase != null && top >= threshold) {
      if (kDebugMode) {
        AppLog.d(
          'PhraseMatcher.matchDecision',
          'MATCH id=${topPhrase.id} label="$topLabel" score=$top threshold=$threshold',
        );
      }
      final reason = topPhrase.matchMode == PhraseMatchingMode.flexible &&
              flexDiag != null
          ? 'Match: "$topLabel" (Flexible) ${flexDiag.componentsSummary}.'
          : 'Match: "$topLabel" (mode ${topPhrase.matchMode.uiLabel}, score '
                '${top.toStringAsFixed(2)} ≥ ${threshold.toStringAsFixed(2)}).';
      return PhraseMatchEvaluation(
        match: topPhrase,
        reason: reason,
        normalizedHeard: nHeardBasic,
        normalizedHeardFlexible: nHeardFlex,
        bestScore: top,
        bestPhraseLabel: topLabel,
        flexible: flexDiag,
      );
    }

    final modeLabel = topPhrase?.matchMode.uiLabel ?? '';
    if (kDebugMode) {
      AppLog.d(
        'PhraseMatcher.matchDecision',
        'no threshold pass — best="$topLabel" score=$top need $threshold',
      );
    }
    final failReason = topPhrase == null
        ? 'No match: could not score phrases.'
        : topPhrase.matchMode == PhraseMatchingMode.flexible && flexDiag != null
            ? 'No match: best "$topLabel" (Flexible) ${flexDiag.componentsSummary}.'
            : 'No match: best "$topLabel" ($modeLabel) score '
                  '${top.toStringAsFixed(2)} below required '
                  '${threshold.toStringAsFixed(2)}.';
    return PhraseMatchEvaluation(
      match: null,
      reason: failReason,
      normalizedHeard: nHeardBasic,
      normalizedHeardFlexible: nHeardFlex,
      bestScore: top,
      bestPhraseLabel: topLabel,
      flexible: flexDiag,
    );
  }
}

/// Cooldown per phrase id.
final class PhraseTriggerCooldown {
  PhraseTriggerCooldown({this.cooldown = const Duration(seconds: 15)});

  final Duration cooldown;
  final Map<String, DateTime> _lastByPhraseId = {};

  bool canTrigger(String phraseId) {
    final last = _lastByPhraseId[phraseId];
    if (last == null) return true;
    return DateTime.now().difference(last) >= cooldown;
  }

  void recordTrigger(String phraseId) {
    _lastByPhraseId[phraseId] = DateTime.now();
  }

  void clear() => _lastByPhraseId.clear();
}
