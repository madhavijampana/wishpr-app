/// Release and environment metadata for Wishpr (beta / store builds).
///
/// Bump [marketingVersion] and [buildNumber] via `pubspec.yaml` (`version: x.y.z+build`).
abstract final class AppConfig {
  /// Shown in About and support contexts (matches MaterialApp title).
  static const String appDisplayName = 'Wishpr';

  /// Human-readable channel for testers (not a separate build flavor yet).
  static const String releaseChannel = 'beta';

  /// Marketing version; keep in sync with `pubspec.yaml` version field before release.
  static const String marketingVersionPlaceholder = '0.9.0';

  /// Short build note for About / diagnostics.
  static String get versionLabel => '$marketingVersionPlaceholder ($releaseChannel)';

  /// Android `applicationId` / iOS bundle ID should be updated before store release.
  static const String suggestedAndroidApplicationId = 'com.wishpr.app';

  /// Set true only in CI or local release pipelines when cutting a store build.
  static const bool isProductionSigningConfigured = false;
}
