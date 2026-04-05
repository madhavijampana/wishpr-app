import 'package:shared_preferences/shared_preferences.dart';

/// Persists Timer Fail-Safe wall-clock end so expiry can run after app restart.
abstract final class TimerFailsafePrefs {
  static String _key(String uid) => 'wishpr_timer_failsafe_end_ms_v1_$uid';

  static Future<void> setArmEnd(String uid, DateTime endsAt) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_key(uid), endsAt.millisecondsSinceEpoch);
  }

  static Future<DateTime?> getArmEnd(String uid) async {
    final p = await SharedPreferences.getInstance();
    final ms = p.getInt(_key(uid));
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> clear(String uid) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(uid));
  }
}
