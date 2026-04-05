import 'package:shared_preferences/shared_preferences.dart';

/// Shared preferences for Timer Fail-Safe and Quick Trigger profile phrase.
abstract final class SafetyPrefs {
  static String _phraseKey(String uid) => 'wishpr_safety_phrase_id_v1_$uid';

  /// Phrase document id used when timer expires or quick trigger fires.
  static Future<String?> getSafetyPhraseId(String uid) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_phraseKey(uid));
  }

  static Future<void> setSafetyPhraseId(String uid, String phraseId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_phraseKey(uid), phraseId);
  }
}
