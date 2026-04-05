import 'package:permission_handler/permission_handler.dart';

/// Types of OS permissions Wishpr uses (speech prep, safety, alerts).
enum WishprPermission {
  microphone,
  locationWhenInUse,
  notification,

  /// Android: `SEND_SMS` for background-style direct send. Not used on iOS
  /// (SMS always goes through the system Messages composer).
  smsSend,
}

/// Centralized permission checks and requests for production use.
///
/// Android: pair with `AndroidManifest.xml` `uses-permission`.
/// iOS: pair with `Info.plist` usage strings (see `ios/Runner/IOS_PRIVACY_KEYS.txt`).
/// Settings UI rows: [WishprPermissionSupport] in `lib/platform/`.
class PermissionService {
  const PermissionService();

  Permission _map(WishprPermission kind) {
    switch (kind) {
      case WishprPermission.microphone:
        return Permission.microphone;
      case WishprPermission.locationWhenInUse:
        return Permission.locationWhenInUse;
      case WishprPermission.notification:
        return Permission.notification;
      case WishprPermission.smsSend:
        return Permission.sms;
    }
  }

  Future<PermissionStatus> status(WishprPermission kind) async {
    return _map(kind).status;
  }

  Future<PermissionStatus> request(WishprPermission kind) async {
    return _map(kind).request();
  }

  /// Opens the app’s page in system settings (e.g. after permanent denial).
  Future<bool> openAppSettingsPage() => openAppSettings();

  /// Whether the permission allows the feature to run.
  bool isAllowed(PermissionStatus status) {
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited ||
        status == PermissionStatus.provisional;
  }

  /// Short label for list tiles and dialogs.
  String statusLabel(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Allowed';
      case PermissionStatus.limited:
        return 'Limited access';
      case PermissionStatus.provisional:
        return 'Provisional';
      case PermissionStatus.denied:
        return 'Not allowed — tap to allow';
      case PermissionStatus.restricted:
        return 'Restricted on this device';
      case PermissionStatus.permanentlyDenied:
        return 'Blocked — open Settings to enable';
    }
  }
}
