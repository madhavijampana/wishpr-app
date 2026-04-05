import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore/contact_document.dart';
import 'firestore_paths.dart';

class ContactsRepository {
  ContactsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirestorePaths.contactsCol(_db, uid);

  Stream<List<ContactDocument>> watchContacts(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ContactDocument.fromFirestore).toList());
  }

  /// Oldest first — used as “primary” trusted contact order for Guard actions.
  Future<List<ContactDocument>> fetchContactsOnceForActions(String uid) async {
    final snap = await _col(uid).orderBy('createdAt').get();
    return snap.docs.map(ContactDocument.fromFirestore).toList();
  }

  /// Newest first — matches [watchContacts] list order for phrase recipient UI.
  Future<List<ContactDocument>> fetchContactsOnceNewestFirst(String uid) async {
    final snap = await _col(uid).orderBy('createdAt', descending: true).get();
    return snap.docs.map(ContactDocument.fromFirestore).toList();
  }

  Future<void> addContact({
    required String uid,
    required String name,
    required String phone,
    required String relationship,
    required String alertMethod,
  }) async {
    final doc = ContactDocument(
      id: '',
      name: name.trim(),
      phone: phone.trim(),
      relationship: relationship.trim(),
      alertMethod: alertMethod,
    );
    await _col(uid).add(doc.toCreateMap());
  }

  Future<void> updateContact({
    required String uid,
    required String contactId,
    required ContactDocument contact,
  }) async {
    await _col(uid).doc(contactId).update(contact.toUpdateMap());
  }

  Future<void> deleteContact({
    required String uid,
    required String contactId,
  }) async {
    await _col(uid).doc(contactId).delete();
  }
}
