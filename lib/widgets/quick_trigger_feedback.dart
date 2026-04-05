import 'package:flutter/material.dart';

import '../services/quick_trigger_coordinator.dart';
import '../services/quick_trigger_messages.dart';
import 'app_scaffold_messenger.dart';

void showQuickTriggerAttemptFeedback(
  BuildContext? context,
  QuickTriggerAttempt result,
) {
  if (result == QuickTriggerAttempt.fired) return;
  final text = result == QuickTriggerAttempt.skippedBusy
      ? QuickTriggerMessages.busy
      : QuickTriggerMessages.cooldown;
  final messenger = context != null
      ? ScaffoldMessenger.maybeOf(context)
      : wishprScaffoldMessengerKey.currentState;
  messenger?.showSnackBar(SnackBar(content: Text(text)));
}
