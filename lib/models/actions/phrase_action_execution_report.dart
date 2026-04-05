import 'action_execution_result.dart';
import '../firestore/trigger_location_snapshot.dart';

/// Outcome of running the action executor for one phrase match.
class PhraseActionExecutionReport {
  const PhraseActionExecutionReport({
    required this.results,
    required this.executionSummary,
    required this.status,
    this.locationSnapshot,
  });

  final List<ActionExecutionResult> results;
  final String executionSummary;

  /// `Completed` | `Partial` | `Failed` — stored as trigger [TriggerEventDocument.status].
  final String status;
  final TriggerLocationSnapshot? locationSnapshot;

  List<Map<String, dynamic>> resultsToFirestore() {
    return results.map((r) => r.toFirestoreMap()).toList();
  }

  /// Human-readable bullets for UI.
  static String buildSummaryLines(List<ActionExecutionResult> results) {
    if (results.isEmpty) {
      return 'No safety actions were enabled for this phrase.';
    }
    return results.map((r) => '• ${r.message}').join('\n');
  }

  static String deriveStatus(List<ActionExecutionResult> results) {
    if (results.any((r) => r.status == 'failed')) {
      return 'Partial';
    }
    return 'Completed';
  }
}
