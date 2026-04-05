import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final DateTime? createdAt;

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final created = data['createdAt'];
    return UserProfile(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'fullName': fullName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
