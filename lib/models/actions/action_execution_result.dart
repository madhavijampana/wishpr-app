import 'phrase_guard_action.dart';

/// One step in the post-match execution pipeline (persisted on the trigger doc).
class ActionExecutionResult {
  const ActionExecutionResult({
    required this.action,
    required this.status,
    required this.message,
    this.executedAt,
    this.detail,
  });

  final PhraseGuardAction action;

  /// `success` | `failed` | `queued` | `prepared` | `deferred` | `skipped`
  final String status;
  final String message;

  /// When this step finished (UTC), if recorded.
  final DateTime? executedAt;

  final Map<String, dynamic>? detail;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'action': action.firestoreId,
      'status': status,
      'message': message,
      if (executedAt != null) 'executedAt': executedAt!.toUtc().toIso8601String(),
      if (detail != null && detail!.isNotEmpty) 'detail': detail,
    };
  }

  static ActionExecutionResult? tryFromFirestoreMap(Map<String, dynamic> map) {
    final action = PhraseGuardAction.tryParse(map['action'] as String?);
    if (action == null) return null;
    final detailRaw = map['detail'];
    final ts = map['executedAt'] as String?;
    return ActionExecutionResult(
      action: action,
      status: map['status'] as String? ?? 'unknown',
      message: map['message'] as String? ?? '',
      executedAt: DateTime.tryParse(ts ?? '')?.toUtc(),
      detail: detailRaw is Map
          ? Map<String, dynamic>.from(detailRaw)
          : null,
    );
  }
}
