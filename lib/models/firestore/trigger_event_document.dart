import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../actions/action_execution_result.dart';
import 'trigger_location_snapshot.dart';

/// Firestore: `users/{uid}/trigger_events/{id}`
///
/// New events use [phraseLabel], [phraseText], [triggeredAt], [status], [userId].
/// Legacy docs may only have `phrase` and `occurredAt`; [fromFirestore] maps those.
/// How the history row was created.
enum TriggerEventSource {
  test,
  speech,
  timer,
  quickTrigger,
}

class TriggerEventDocument {
  const TriggerEventDocument({
    required this.id,
    required this.phraseLabel,
    required this.phraseText,
    required this.actionSummary,
    required this.status,
    required this.userId,
    this.triggeredAt,
    this.phraseId,
    this.recognizedSpeech,
    this.executionResults = const [],
    this.executionSummary = '',
    this.locationSnapshot,
    this.source,
  });

  final String id;
  final String phraseLabel;
  final String phraseText;
  final String actionSummary;
  final String status;
  final String userId;
  final DateTime? triggeredAt;

  /// Phrase doc id when matched from Guard Mode.
  final String? phraseId;

  /// Last finalized speech string Guard Mode used for the match (optional).
  final String? recognizedSpeech;

  /// Raw maps as stored in Firestore (`action`, `status`, `message`, `detail`).
  final List<Map<String, dynamic>> executionResults;

  /// Bullet-style summary shown in Guard Mode and History.
  final String executionSummary;

  final TriggerLocationSnapshot? locationSnapshot;

  /// test · speech · timer · quick_trigger (see [TriggerEventSource]).
  final TriggerEventSource? source;

  String get whenLabel {
    if (triggeredAt == null) return '—';
    return DateFormat('MMM d, y · h:mm a').format(triggeredAt!);
  }

  /// Parsed steps for the trigger details screen.
  List<ActionExecutionResult> get parsedExecutionResults {
    return executionResults
        .map(ActionExecutionResult.tryFromFirestoreMap)
        .whereType<ActionExecutionResult>()
        .toList();
  }

  factory TriggerEventDocument.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final t = data['triggeredAt'] ?? data['occurredAt'];
    final legacyPhrase = data['phrase'] as String? ?? '';
    return TriggerEventDocument(
      id: doc.id,
      phraseLabel: data['phraseLabel'] as String? ?? legacyPhrase,
      phraseText: data['phraseText'] as String? ?? '',
      actionSummary: data['actionSummary'] as String? ?? '',
      status: data['status'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      triggeredAt: t is Timestamp ? t.toDate() : null,
      phraseId: data['phraseId'] as String?,
      recognizedSpeech: data['recognizedSpeech'] as String?,
      executionResults: _parseMapList(data['executionResults']),
      executionSummary: data['executionSummary'] as String? ?? '',
      locationSnapshot: TriggerLocationSnapshot.tryFromFirestore(
        data['locationSnapshot'],
      ),
      source: _parseSource(data['source'] as String?),
    );
  }

  static TriggerEventSource? _parseSource(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw) {
      case 'test':
        return TriggerEventSource.test;
      case 'speech':
        return TriggerEventSource.speech;
      case 'timer':
        return TriggerEventSource.timer;
      case 'quick_trigger':
        return TriggerEventSource.quickTrigger;
      default:
        return null;
    }
  }

  static String _sourceToFirestore(TriggerEventSource s) {
    switch (s) {
      case TriggerEventSource.test:
        return 'test';
      case TriggerEventSource.speech:
        return 'speech';
      case TriggerEventSource.timer:
        return 'timer';
      case TriggerEventSource.quickTrigger:
        return 'quick_trigger';
    }
  }

  Map<String, dynamic> toCreateMap() {
    final map = <String, dynamic>{
      'phraseLabel': phraseLabel,
      'phraseText': phraseText,
      'actionSummary': actionSummary,
      'status': status,
      'triggeredAt': FieldValue.serverTimestamp(),
      'userId': userId,
    };
    if (phraseId != null && phraseId!.isNotEmpty) {
      map['phraseId'] = phraseId;
    }
    if (recognizedSpeech != null && recognizedSpeech!.isNotEmpty) {
      map['recognizedSpeech'] = recognizedSpeech;
    }
    if (executionResults.isNotEmpty) {
      map['executionResults'] = executionResults;
    }
    if (executionSummary.isNotEmpty) {
      map['executionSummary'] = executionSummary;
    }
    if (locationSnapshot != null) {
      map['locationSnapshot'] = locationSnapshot!.toFirestoreMap();
    }
    if (source != null) {
      map['source'] = _sourceToFirestore(source!);
    }
    return map;
  }
}

List<Map<String, dynamic>> _parseMapList(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}
