import 'wishpr_platform.dart';

/// Non-technical, user-facing lines for platform differences.
abstract final class WishprPlatformUserCopy {
  static String get settingsDeviceSectionTitle => 'This device';

  static String get settingsDeviceBody {
    if (WishprPlatform.isIOS) {
      return 'Wishpr works on iPhone. SMS safety steps open the Messages app with your '
          'text ready to send. Phone steps open the Phone app. Automatic background '
          'SMS (without opening Messages) is not available on iOS — that option is '
          'Android-only.';
    }
    if (WishprPlatform.isAndroid) {
      return 'On Android, Wishpr can send SMS in the background when you allow it, or '
          'open your SMS app if not. Phone steps open your dialer.';
    }
    return 'Some safety steps depend on your device and browser.';
  }

  static String get guardSpeechFootnote {
    if (WishprPlatform.isIOS) {
      return 'Speech recognition uses Apple’s on-device engine where available.';
    }
    return '';
  }

  /// Shown near SMS template on the phrase editor.
  static String get phraseSmsBehaviorFootnote {
    if (WishprPlatform.isIOS) {
      return 'On iPhone, Wishpr opens the Messages app with your text ready to send. '
          'Automatic background SMS is not available on iOS (Android-only).';
    }
    if (WishprPlatform.isAndroid) {
      return 'On Android, Wishpr tries to send SMS in the background when permission '
          'is granted; many devices still open the SMS app instead. Automatic send is '
          'best-effort only.';
    }
    return 'SMS uses your device’s messaging app where needed.';
  }
}
