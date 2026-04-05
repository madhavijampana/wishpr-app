import 'package:cloud_firestore/cloud_firestore.dart';

class ContactDocument {
  const ContactDocument({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.alertMethod,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String relationship;
  final String alertMethod;
  final DateTime? createdAt;

  factory ContactDocument.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final created = data['createdAt'];
    return ContactDocument(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      alertMethod: data['alertMethod'] as String? ?? 'SMS',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'alertMethod': alertMethod,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Update payload (does not change [createdAt]).
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'alertMethod': alertMethod,
    };
  }
}
