import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Signed-in user id, or `null` if Firebase is not initialized or there is no user.
String? currentWishprUid() {
  try {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    return null;
  }
}
