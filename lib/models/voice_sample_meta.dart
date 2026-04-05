import 'package:cloud_firestore/cloud_firestore.dart';

/// Metadata for an optional voice sample (no audio matching yet).
class VoiceSampleMeta {
  const VoiceSampleMeta({
    required this.durationSec,
    this.recordedAt,
    this.localFileName,
  });

  final double durationSec;
  final DateTime? recordedAt;

  /// Optional relative name under app documents (device-local).
  final String? localFileName;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'durationSec': durationSec,
      if (recordedAt != null) 'recordedAt': Timestamp.fromDate(recordedAt!),
      if (localFileName != null && localFileName!.isNotEmpty)
        'localFileName': localFileName,
    };
  }

  factory VoiceSampleMeta.fromMap(Map<String, dynamic> map) {
    final ts = map['recordedAt'];
    return VoiceSampleMeta(
      durationSec: (map['durationSec'] as num?)?.toDouble() ?? 0,
      recordedAt: ts is Timestamp ? ts.toDate() : null,
      localFileName: map['localFileName'] as String?,
    );
  }

  static List<VoiceSampleMeta> listFromFirestore(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => VoiceSampleMeta.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}
