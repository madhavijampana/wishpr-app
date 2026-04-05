import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore/phrase_document.dart';
import '../models/phrase_matching_mode.dart';
import '../models/voice_sample_meta.dart';
import 'firestore_paths.dart';

class PhrasesRepository {
  PhrasesRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirestorePaths.phrasesCol(_db, uid);

  Stream<List<PhraseDocument>> watchPhrases(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PhraseDocument.fromFirestore).toList());
  }

  /// One-shot fetch for Guard Mode (no live subscription while listening).
  Future<List<PhraseDocument>> fetchPhrasesOnce(String uid) async {
    final snap = await _col(uid).orderBy('createdAt', descending: true).get();
    return snap.docs.map(PhraseDocument.fromFirestore).toList();
  }

  Future<void> addPhrase({
    required String uid,
    required String label,
    required String secretPhrase,
    required String category,
    required bool active,
    required bool sendSms,
    required bool shareLocation,
    required bool callContact,
    required bool startRecording,
    List<String> smsContactIds = const [],
    List<String> callContactIds = const [],
    PhraseMatchingMode matchMode = PhraseMatchingMode.flexible,
    String smsTemplate = '',
    List<VoiceSampleMeta> voiceSamples = const [],
  }) async {
    final phrase = PhraseDocument(
      id: '',
      label: label.trim(),
      secretPhrase: secretPhrase.trim(),
      category: category,
      active: active,
      sendSms: sendSms,
      shareLocation: shareLocation,
      callContact: callContact,
      startRecording: startRecording,
      smsContactIds: smsContactIds,
      callContactIds: callContactIds,
      matchMode: matchMode,
      smsTemplate: smsTemplate.trim(),
      voiceSamples: voiceSamples,
    );
    await _col(uid).add(phrase.toCreateMap());
  }

  Future<void> updatePhrase({
    required String uid,
    required String phraseId,
    required PhraseDocument phrase,
  }) async {
    await _col(uid).doc(phraseId).update(phrase.toUpdateMap());
  }

  Future<void> deletePhrase({
    required String uid,
    required String phraseId,
  }) async {
    await _col(uid).doc(phraseId).delete();
  }
}
