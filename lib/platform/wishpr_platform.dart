import 'package:flutter/foundation.dart';

/// Cross-platform runtime facts for Wishpr safety features.
///
/// Uses [defaultTargetPlatform] only (no `dart:io`) so this file is valid on web builds.
abstract final class WishprPlatform {
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isWeb => kIsWeb;

  /// Android: `SEND_SMS` + Wishpr’s native MethodChannel direct send path.
  static bool get supportsAndroidDirectSms => isAndroid;

  /// Native code can raise Quick Trigger via BasicMessageChannel (Android today).
  static bool get supportsNativeQuickTriggerBridge => isAndroid;

  static String get shortPlatformLabel {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.android => 'Android',
      _ => 'this device',
    };
  }
}
