import 'package:cloud_firestore/cloud_firestore.dart';

import '../phrase_matching_mode.dart';
import '../voice_sample_meta.dart';

class PhraseDocument {
  const PhraseDocument({
    required this.id,
    required this.label,
    required this.secretPhrase,
    required this.category,
    required this.active,
    required this.sendSms,
    required this.shareLocation,
    required this.callContact,
    required this.startRecording,
    this.createdAt,
    this.smsContactIds = const [],
    this.callContactIds = const [],
    this.matchMode = PhraseMatchingMode.flexible,
    this.smsTemplate = '',
    this.voiceSamples = const [],
  });

  final String id;
  final String label;
  final String secretPhrase;
  final String category;
  final bool active;
  final bool sendSms;
  final bool shareLocation;
  final bool callContact;
  final bool startRecording;
  final DateTime? createdAt;

  /// Trusted contact doc ids for **Send SMS** (order = priority).
  final List<String> smsContactIds;

  /// Trusted contact doc ids for **Call Contact** (order = priority).
  final List<String> callContactIds;

  final PhraseMatchingMode matchMode;

  /// Custom SMS body template; placeholders — see [SmsTemplateHelper].
  final String smsTemplate;

  /// Optional voice sample metadata (1–3); audio matching not implemented yet.
  final List<VoiceSampleMeta> voiceSamples;

  factory PhraseDocument.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final created = data['createdAt'];
    return PhraseDocument(
      id: doc.id,
      label: data['label'] as String? ?? '',
      secretPhrase: data['secretPhrase'] as String? ?? '',
      category: data['category'] as String? ?? '',
      active: data['active'] as bool? ?? true,
      sendSms: data['sendSms'] as bool? ?? false,
      shareLocation: data['shareLocation'] as bool? ?? false,
      callContact: data['callContact'] as bool? ?? false,
      startRecording: data['startRecording'] as bool? ?? false,
      createdAt: created is Timestamp ? created.toDate() : null,
      smsContactIds: _stringIdList(data['smsContactIds']),
      callContactIds: _stringIdList(data['callContactIds']),
      matchMode: PhraseMatchingMode.parse(data['matchMode'] as String?),
      smsTemplate: data['smsTemplate'] as String? ?? '',
      voiceSamples: VoiceSampleMeta.listFromFirestore(data['voiceSamples']),
    );
  }

  static List<String> _stringIdList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'label': label,
      'secretPhrase': secretPhrase,
      'category': category,
      'active': active,
      'sendSms': sendSms,
      'shareLocation': shareLocation,
      'callContact': callContact,
      'startRecording': startRecording,
      'smsContactIds': smsContactIds,
      'callContactIds': callContactIds,
      'matchMode': matchMode.firestoreValue,
      'smsTemplate': smsTemplate,
      'voiceSamples': voiceSamples.map((e) => e.toFirestoreMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'label': label,
      'secretPhrase': secretPhrase,
      'category': category,
      'active': active,
      'sendSms': sendSms,
      'shareLocation': shareLocation,
      'callContact': callContact,
      'startRecording': startRecording,
      'smsContactIds': smsContactIds,
      'callContactIds': callContactIds,
      'matchMode': matchMode.firestoreValue,
      'smsTemplate': smsTemplate,
      'voiceSamples': voiceSamples.map((e) => e.toFirestoreMap()).toList(),
    };
  }
}
