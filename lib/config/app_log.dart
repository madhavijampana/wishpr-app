import 'package:flutter/foundation.dart';

/// Debug-only logging. No-ops in release/profile builds.
abstract final class AppLog {
  static void d(String message, [Object? detail]) {
    if (kDebugMode) {
      debugPrint('[Wishpr] $message${detail != null ? ': $detail' : ''}');
    }
  }

  static void w(String message, [Object? detail]) {
    if (kDebugMode) {
      debugPrint('[Wishpr WARN] $message${detail != null ? ': $detail' : ''}');
    }
  }

  static void e(String message, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[Wishpr ERROR] $message: $error');
      if (stack != null) {
        debugPrint(stack.toString());
      }
    }
  }
}
