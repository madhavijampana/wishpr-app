import 'package:shared_preferences/shared_preferences.dart';

/// First-run safety disclaimer acceptance (device-local).
abstract final class DisclaimerPrefs {
  static const String prefsKey = 'disclaimerAccepted';

  static Future<bool> isAccepted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(prefsKey) ?? false;
  }

  static Future<void> markAccepted() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(prefsKey, true);
  }
}
