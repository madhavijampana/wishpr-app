import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_log.dart';
import '../models/actions/phrase_action_execution_report.dart';
import '../models/firestore/guard_mode_sample_trigger.dart';
import '../models/firestore/phrase_document.dart';
import '../models/firestore/trigger_event_document.dart';
import 'phrase_match_helper.dart';
import 'firestore_paths.dart';

class TriggerEventsRepository {
  TriggerEventsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirestorePaths.triggerEventsCol(_db, uid);

  Stream<List<TriggerEventDocument>> watchTriggerEvents(String uid) {
    return _col(uid)
        .orderBy('triggeredAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map(TriggerEventDocument.fromFirestore).toList(),
        );
  }

  /// Writes the fixed sample event used by Guard Mode “Test Trigger”.
  Future<void> addSampleTestTrigger(String uid) async {
    final event = TriggerEventDocument(
      id: '',
      phraseLabel: GuardModeSampleTrigger.phraseLabel,
      phraseText: GuardModeSampleTrigger.phraseText,
      actionSummary: GuardModeSampleTrigger.actionSummary,
      status: GuardModeSampleTrigger.status,
      userId: uid,
      executionSummary:
          'Manual test — no automated actions were run for this sample.',
      executionResults: const [],
      source: TriggerEventSource.test,
    );
    await _col(uid).add(event.toCreateMap());
  }

  /// Guard Mode: phrase matched from speech; persists execution report and optional speech text.
  Future<void> addPhraseTriggerFromSpeech({
    required String uid,
    required PhraseDocument phrase,
    required PhraseActionExecutionReport report,
    String? recognizedSpeech,
  }) async {
    final event = TriggerEventDocument(
      id: '',
      phraseLabel: phrase.label,
      phraseText: phrase.secretPhrase,
      actionSummary: PhraseMatchHelper.buildActionSummary(phrase),
      status: report.status,
      userId: uid,
      phraseId: phrase.id,
      recognizedSpeech: recognizedSpeech,
      executionResults: report.resultsToFirestore(),
      executionSummary: report.executionSummary,
      locationSnapshot: report.locationSnapshot,
      source: TriggerEventSource.speech,
    );
    AppLog.d(
      'TriggerEventsRepository.addPhraseTriggerFromSpeech',
      'write attempted phraseId=${phrase.id}',
    );
    await _col(uid).add(event.toCreateMap());
    AppLog.d(
      'TriggerEventsRepository.addPhraseTriggerFromSpeech',
      'write completed phraseId=${phrase.id}',
    );
  }
}
