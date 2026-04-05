import '../models/firestore/phrase_document.dart';
import 'phrase_matcher.dart';

export 'phrase_matcher.dart';

/// Legacy static entry points (same as [PhraseMatcher]).
abstract final class PhraseMatchHelper {
  static String normalize(String input) => PhraseMatcher.normalize(input);

  static String normalizeFlexible(String input) =>
      PhraseMatcher.normalizeFlexible(input);

  static PhraseMatchEvaluation evaluate(
    String heard,
    Iterable<PhraseDocument> phrases,
  ) =>
      PhraseMatcher.evaluate(heard, phrases);

  static String buildActionSummary(PhraseDocument phrase) =>
      PhraseMatcher.buildActionSummary(phrase);
}
