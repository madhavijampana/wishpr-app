/// Copy, layout, and shape constants for Wishpr (UI-only).
abstract final class WishprStrings {
  static const String appName = 'Wishpr';
  static const String tagline = 'Turn words into action';
}

/// Copy for Firestore-backed lists (phrases, contacts, history).
abstract final class WishprFirestoreCopy {
  static const String noPhrasesTitle = 'No secret phrases yet';
  static const String noPhrasesBody =
      'Secret phrases are words or short lines only you would say out loud. '
      'When Guard Mode hears one, Wishpr can alert your trusted contacts and run the actions you pick.';
  static const String noContactsTitle = 'No trusted contacts yet';
  static const String noContactsBody =
      'Trusted contacts receive SMS or calls when a phrase triggers — if you enabled those actions. '
      'Add at least one person with a real phone number so Wishpr can reach them.';
  static const String noHistoryTitle = 'No safety events yet';
  static const String noHistoryBody =
      'When a phrase matches in Guard Mode (or you use Test Trigger), a record appears here with what ran. '
      'Use the Home tab to start listening when you want protection active.';
  static const String loadErrorTitle = 'Couldn’t load this list';
  static const String loadErrorBody =
      'Check your internet connection. If you’re online, pull to retry or tap below.';
  static const String retry = 'Try again';
  static const String signInRequired =
      'Sign in on the previous screen to sync phrases, contacts, and history across your devices.';
}

abstract final class WishprLayout {
  static const double screenPaddingH = 24;
  static const double screenPaddingV = 24;
  static const double settingsPaddingH = 16;

  static const double cardRadius = 16;
  static const double fieldRadius = 14;
  static const double guardCardRadius = 20;
  static const double iconTileRadius = 12;
  static const double activityTileRadius = 14;
}
