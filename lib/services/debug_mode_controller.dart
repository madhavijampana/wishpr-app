import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global debug/developer UI flag (Guard diagnostics, raw errors). Synced per user.
class DebugModeController extends ValueNotifier<bool> {
  DebugModeController._() : super(false);

  static final DebugModeController instance = DebugModeController._();

  static String _key(String uid) => 'wishpr_developer_mode_v1_$uid';

  Future<void> hydrate(String? uid) async {
    if (uid == null || uid.isEmpty) {
      value = false;
      return;
    }
    final p = await SharedPreferences.getInstance();
    value = p.getBool(_key(uid)) ?? false;
  }

  Future<void> setEnabled(String uid, bool enabled) async {
    value = enabled;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(uid), enabled);
  }
}
