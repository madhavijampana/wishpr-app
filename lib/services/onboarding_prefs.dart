import 'package:shared_preferences/shared_preferences.dart';

/// Persists first-run onboarding completion per Firebase user id.
abstract final class OnboardingPrefs {
  static String _key(String uid) => 'wishpr_onboarding_v1_$uid';

  static Future<bool> isComplete(String uid) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key(uid)) ?? false;
  }

  static Future<void> markComplete(String uid) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(uid), true);
  }
}
