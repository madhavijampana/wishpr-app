import 'package:shared_preferences/shared_preferences.dart';

/// One-time in-app explanation of trusted contacts (not an OS permission sheet).
abstract final class TrustedContactsEducationPrefs {
  static const String _key = 'wishpr_trusted_contacts_education_v1';

  static Future<bool> wasShown() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key) ?? false;
  }

  static Future<void> markShown() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
  }
}
