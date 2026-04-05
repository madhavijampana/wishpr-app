/// How Guard Mode compares spoken text to [PhraseDocument.secretPhrase].
enum PhraseMatchingMode {
  /// Normalized equality or full phrase contained in heard.
  exact,

  /// Fuzzy / partial / similarity (default).
  flexible,

  /// Normalized string equality only (strictest).
  highSecurity;

  static PhraseMatchingMode parse(String? raw) {
    switch (raw) {
      case 'exact':
        return PhraseMatchingMode.exact;
      case 'highSecurity':
        return PhraseMatchingMode.highSecurity;
      case 'flexible':
      default:
        return PhraseMatchingMode.flexible;
    }
  }

  String get firestoreValue {
    switch (this) {
      case PhraseMatchingMode.exact:
        return 'exact';
      case PhraseMatchingMode.flexible:
        return 'flexible';
      case PhraseMatchingMode.highSecurity:
        return 'highSecurity';
    }
  }

  String get uiLabel {
    switch (this) {
      case PhraseMatchingMode.exact:
        return 'Exact';
      case PhraseMatchingMode.flexible:
        return 'Flexible (default)';
      case PhraseMatchingMode.highSecurity:
        return 'High security (exact only)';
    }
  }
}
