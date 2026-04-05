import '../models/actions/action_execution_result.dart';
import '../models/actions/phrase_action_execution_report.dart';
import '../models/actions/phrase_guard_action.dart';
import '../models/firestore/contact_document.dart';
import '../models/firestore/phrase_document.dart';
import '../config/app_log.dart';
import '../models/firestore/trigger_location_snapshot.dart';
import 'contacts_repository.dart';
import 'permission_service.dart';
import 'sms_template_helper.dart';
import 'trusted_contact_selector.dart';
import 'wishpr_comm_launcher_service.dart';
import 'wishpr_location_service.dart';
import 'wishpr_sms_service.dart';

/// Runs phrase actions in order: location → SMS → call → recording.
class PhraseActionExecutor {
  PhraseActionExecutor({
    PermissionService? permissionService,
    WishprLocationService? locationService,
    ContactsRepository? contactsRepository,
    WishprCommLauncherService? commLauncher,
    WishprSmsService? smsService,
  })  : _permissions = permissionService ?? const PermissionService(),
        _location = locationService ?? const WishprLocationService(),
        _contacts = contactsRepository ?? ContactsRepository(),
        _launcher = commLauncher ?? const WishprCommLauncherService(),
        _sms = smsService ?? WishprSmsService();

  final PermissionService _permissions;
  final WishprLocationService _location;
  final ContactsRepository _contacts;
  final WishprCommLauncherService _launcher;
  final WishprSmsService _sms;

  Future<PhraseActionExecutionReport> execute(
    PhraseDocument phrase,
    String uid,
  ) async {
    AppLog.d('PhraseActionExecutor.execute', 'start phraseId=${phrase.id}');
    final results = <ActionExecutionResult>[];
    TriggerLocationSnapshot? snapshot;

    final steps = _plannedSteps(phrase);
    if (steps.isEmpty) {
      return PhraseActionExecutionReport(
        results: const [],
        executionSummary:
            PhraseActionExecutionReport.buildSummaryLines(const []),
        status: 'Completed',
        locationSnapshot: null,
      );
    }

    List<ContactDocument> contacts = const [];
    if (phrase.sendSms || phrase.callContact) {
      try {
        contacts = await _contacts.fetchContactsOnceForActions(uid);
      } catch (_) {
        contacts = const [];
      }
    }

    for (final step in steps) {
      if (step == PhraseGuardAction.shareLocation) {
        final outcome = await _location.captureCurrentLocation(
          permissionService: _permissions,
        );
        if (outcome.isSuccess) {
          final pos = outcome.position!;
          final at = DateTime.now();
          snapshot = TriggerLocationSnapshot(
            latitude: pos.latitude,
            longitude: pos.longitude,
            accuracyMeters: pos.accuracy.isFinite ? pos.accuracy : null,
            capturedAt: at,
          );
          results.add(
            ActionExecutionResult(
              action: step,
              status: 'success',
              message:
                  'Location captured (${snapshot.latitude.toStringAsFixed(5)}, ${snapshot.longitude.toStringAsFixed(5)}).',
              executedAt: DateTime.now().toUtc(),
              detail: {
                'latitude': pos.latitude,
                'longitude': pos.longitude,
                if (pos.accuracy.isFinite) 'accuracyMeters': pos.accuracy,
              },
            ),
          );
        } else {
          results.add(
            ActionExecutionResult(
              action: step,
              status: 'failed',
              message: outcome.errorMessage ?? 'Location capture failed.',
              executedAt: DateTime.now().toUtc(),
              detail: {
                if (outcome.errorMessage != null) 'error': outcome.errorMessage,
              },
            ),
          );
        }
      } else if (step == PhraseGuardAction.sendSms) {
        final recipients = TrustedContactSelector.smsRecipientsOrdered(
          contacts,
          phrase.smsContactIds,
        );
        if (recipients.isEmpty) {
          results.add(
            ActionExecutionResult(
              action: step,
              status: 'failed',
              message: phrase.smsContactIds.isNotEmpty
                  ? 'SMS — check selected contacts have valid numbers.'
                  : 'SMS — add a trusted contact with a phone number.',
              executedAt: DateTime.now().toUtc(),
              detail: {
                'reason': 'no_eligible_contact',
                if (phrase.smsContactIds.isNotEmpty)
                  'preferredIds': phrase.smsContactIds,
              },
            ),
          );
        } else {
          final body = SmsTemplateHelper.resolve(
            phrase: phrase,
            locationSnapshot: snapshot,
          );
          final rows = await _sms.sendToRecipients(
            recipients: recipients,
            messageBody: body,
          );
          final maps = rows.map((r) => r.toDetailMap()).toList();
          final anyOk = rows.any(
            (r) =>
                r.outcome == WishprSmsRecipientOutcome.sentDirect ||
                r.outcome == WishprSmsRecipientOutcome.fallbackComposer,
          );
          results.add(
            ActionExecutionResult(
              action: step,
              status: anyOk ? 'success' : 'failed',
              message: _summarizeSmsResults(rows),
              executedAt: DateTime.now().toUtc(),
              detail: {'smsPerContact': maps},
            ),
          );
        }
      } else if (step == PhraseGuardAction.callContact) {
        final contact = TrustedContactSelector.forCall(
          contacts,
          preferredContactIds: phrase.callContactIds,
        );
        if (contact == null) {
          results.add(
            ActionExecutionResult(
              action: step,
              status: 'failed',
              message: phrase.callContactIds.isNotEmpty
                  ? 'Call not started — check selected contacts have valid numbers.'
                  : 'Call not started — add a trusted contact with a phone number.',
              executedAt: DateTime.now().toUtc(),
              detail: {
                'reason': 'no_eligible_contact',
                if (phrase.callContactIds.isNotEmpty)
                  'preferredIds': phrase.callContactIds,
              },
            ),
          );
        } else {
          final phone = TrustedContactSelector.normalizePhoneForDevice(
            contact.phone,
          );
          if (phone == null) {
            results.add(
              ActionExecutionResult(
                action: step,
                status: 'failed',
                message:
                    'Call not started — ${contact.name} needs a valid phone number.',
                executedAt: DateTime.now().toUtc(),
                detail: {
                  'contactId': contact.id,
                  'contactName': contact.name,
                  'reason': 'invalid_phone',
                },
              ),
            );
          } else {
            final launch = await _launcher.openTelDialer(phone);
            results.add(
              ActionExecutionResult(
                action: step,
                status: launch.opened ? 'success' : 'failed',
                message: launch.opened
                    ? 'Phone dialer opened for ${contact.name}.'
                    : (launch.errorMessage ??
                        'Dialer could not be opened.'),
                executedAt: DateTime.now().toUtc(),
                detail: {
                  'contactId': contact.id,
                  'contactName': contact.name,
                  'targetPhone': phone,
                  if (launch.errorMessage != null && !launch.opened)
                    'error': launch.errorMessage,
                },
              ),
            );
          }
        }
      } else if (step == PhraseGuardAction.startRecording) {
        results.add(
          ActionExecutionResult(
            action: PhraseGuardAction.startRecording,
            status: 'deferred',
            message:
                'Recording not started — post-trigger capture is planned for a future update.',
            executedAt: DateTime.now().toUtc(),
            detail: const {'intent': 'recording_deferred'},
          ),
        );
      }
    }

    final summary = PhraseActionExecutionReport.buildSummaryLines(results);
    final status = PhraseActionExecutionReport.deriveStatus(results);
    AppLog.d('PhraseActionExecutor.execute', 'done status=$status');
    return PhraseActionExecutionReport(
      results: results,
      executionSummary: summary,
      status: status,
      locationSnapshot: snapshot,
    );
  }

  static String _summarizeSmsResults(List<WishprSmsRecipientResult> rows) {
    var direct = 0;
    var fallback = 0;
    var failed = 0;
    for (final r in rows) {
      switch (r.outcome) {
        case WishprSmsRecipientOutcome.sentDirect:
          direct++;
        case WishprSmsRecipientOutcome.fallbackComposer:
          fallback++;
        case WishprSmsRecipientOutcome.failed:
          failed++;
      }
    }
    final parts = <String>[];
    if (direct > 0) parts.add('$direct direct');
    if (fallback > 0) parts.add('$fallback composer fallback');
    if (failed > 0) parts.add('$failed failed');
    return 'SMS: ${parts.isEmpty ? 'no attempts' : parts.join(', ')}.';
  }

  List<PhraseGuardAction> _plannedSteps(PhraseDocument phrase) {
    final steps = <PhraseGuardAction>[];
    if (phrase.shareLocation) steps.add(PhraseGuardAction.shareLocation);
    if (phrase.sendSms) steps.add(PhraseGuardAction.sendSms);
    if (phrase.callContact) steps.add(PhraseGuardAction.callContact);
    if (phrase.startRecording) steps.add(PhraseGuardAction.startRecording);
    return steps;
  }
}
