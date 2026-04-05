import 'package:cloud_firestore/cloud_firestore.dart';

/// Location attached to a trigger event after a successful capture.
class TriggerLocationSnapshot {
  const TriggerLocationSnapshot({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime capturedAt;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      'capturedAt': Timestamp.fromDate(capturedAt),
    };
  }

  static TriggerLocationSnapshot? tryFromFirestore(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final lat = (map['latitude'] as num?)?.toDouble();
    final lng = (map['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    final cap = map['capturedAt'];
    return TriggerLocationSnapshot(
      latitude: lat,
      longitude: lng,
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble(),
      capturedAt: cap is Timestamp ? cap.toDate() : DateTime.now(),
    );
  }

  String get shortLabel {
    final acc = accuracyMeters != null
        ? ' ±${accuracyMeters!.round()} m'
        : '';
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}$acc';
  }
}
