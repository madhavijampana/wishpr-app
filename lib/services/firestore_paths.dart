import 'package:cloud_firestore/cloud_firestore.dart';

/// Collection and document paths for Wishpr Firestore data.
abstract final class FirestorePaths {
  static const String users = 'users';
  static const String contacts = 'contacts';
  static const String phrases = 'phrases';
  static const String triggerEvents = 'trigger_events';

  static DocumentReference<Map<String, dynamic>> userDoc(
    FirebaseFirestore db,
    String uid,
  ) {
    return db.collection(users).doc(uid);
  }

  static CollectionReference<Map<String, dynamic>> contactsCol(
    FirebaseFirestore db,
    String uid,
  ) {
    return userDoc(db, uid).collection(contacts);
  }

  static CollectionReference<Map<String, dynamic>> phrasesCol(
    FirebaseFirestore db,
    String uid,
  ) {
    return userDoc(db, uid).collection(phrases);
  }

  static CollectionReference<Map<String, dynamic>> triggerEventsCol(
    FirebaseFirestore db,
    String uid,
  ) {
    return userDoc(db, uid).collection(triggerEvents);
  }
}
