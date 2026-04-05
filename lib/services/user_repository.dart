import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore/user_profile.dart';
import 'firestore_paths.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Creates or merges the root user profile (`users/{uid}`).
  Future<void> ensureUserProfile({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    final profile = UserProfile(
      uid: uid,
      fullName: fullName,
      email: email,
      createdAt: null,
    );
    await FirestorePaths.userDoc(_db, uid)
        .set(profile.toCreateMap(), SetOptions(merge: true));
  }
}
