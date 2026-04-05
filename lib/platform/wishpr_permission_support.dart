import '../services/permission_service.dart';
import 'wishpr_platform.dart';

/// Which [WishprPermission] rows belong in Settings and runtime prompts.
///
/// iOS: no runtime “SMS send” permission row — Messages opens via composer only.
abstract final class WishprPermissionSupport {
  static bool isManageableInSettings(WishprPermission kind) {
    switch (kind) {
      case WishprPermission.smsSend:
        return WishprPlatform.isAndroid;
      case WishprPermission.microphone:
      case WishprPermission.locationWhenInUse:
      case WishprPermission.notification:
        return true;
    }
  }
}
