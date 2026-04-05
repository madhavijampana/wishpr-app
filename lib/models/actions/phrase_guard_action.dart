/// Configured safety actions for a matched phrase, executed in declaration order.
enum PhraseGuardAction {
  shareLocation('share_location'),
  sendSms('send_sms'),
  callContact('call_contact'),
  startRecording('start_recording');

  const PhraseGuardAction(this.firestoreId);

  /// Value stored in Firestore `executionResults[].action`.
  final String firestoreId;

  static PhraseGuardAction? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final a in PhraseGuardAction.values) {
      if (a.firestoreId == raw) return a;
    }
    return null;
  }
}
