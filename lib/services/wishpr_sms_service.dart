import 'package:flutter/services.dart';

import '../config/app_log.dart';
import '../models/firestore/contact_document.dart';
import '../platform/wishpr_platform.dart';
import 'permission_service.dart';
import 'trusted_contact_selector.dart';
import 'wishpr_comm_launcher_service.dart';

/// How a single SMS attempt completed.
enum WishprSmsRecipientOutcome {
  sentDirect,
  failed,
  fallbackComposer,
}

/// One row for logs / Firestore detail.
class WishprSmsRecipientResult {
  const WishprSmsRecipientResult({
    required this.contactName,
    required this.phone,
    required this.outcome,
    required this.detailMessage,
  });

  final String contactName;
  final String phone;
  final WishprSmsRecipientOutcome outcome;
  final String detailMessage;

  Map<String, dynamic> toDetailMap() {
    return {
      'contactName': contactName,
      'targetPhone': phone,
      'outcome': outcome.name,
      'message': detailMessage,
    };
  }
}

/// Platform-agnostic SMS step: Android may use direct send + composer fallback;
/// iOS and others use the system SMS composer only ([WishprCommLauncherService]).
abstract class WishprSmsSending {
  Future<List<WishprSmsRecipientResult>> sendToRecipients({
    required List<ContactDocument> recipients,
    required String messageBody,
  });
}

/// Best-effort direct SMS on Android via [MethodChannel]; composer fallback per contact.
class WishprSmsService implements WishprSmsSending {
  WishprSmsService({
    PermissionService? permissionService,
    WishprCommLauncher? launcher,
  })  : _permissions = permissionService ?? const PermissionService(),
        _launcher = launcher ?? const WishprCommLauncherService();

  static const MethodChannel _androidSmsChannel =
      MethodChannel('com.example.wishpr_app/sms');

  final PermissionService _permissions;
  final WishprCommLauncher _launcher;

  /// Sends [messageBody] to each [recipients] in order.
  @override
  Future<List<WishprSmsRecipientResult>> sendToRecipients({
    required List<ContactDocument> recipients,
    required String messageBody,
  }) async {
    if (recipients.isEmpty) {
      return const [];
    }

    final results = <WishprSmsRecipientResult>[];
    final tryDirect =
        WishprPlatform.supportsAndroidDirectSms && messageBody.isNotEmpty;

    var directAllowed = false;
    if (tryDirect) {
      final st = await _permissions.request(WishprPermission.smsSend);
      directAllowed = _permissions.isAllowed(st);
      if (!directAllowed) {
        AppLog.d('WishprSmsService: SMS permission not granted, using composer');
      }
    }

    for (final contact in recipients) {
      final phone = TrustedContactSelector.normalizePhoneForDevice(
        contact.phone,
      );
      if (phone == null) {
        results.add(
          WishprSmsRecipientResult(
            contactName: contact.name,
            phone: contact.phone,
            outcome: WishprSmsRecipientOutcome.failed,
            detailMessage: 'Invalid phone number.',
          ),
        );
        continue;
      }

      if (tryDirect && directAllowed) {
        final direct = await _tryAndroidDirectSms(phone, messageBody);
        if (direct.ok) {
          results.add(
            WishprSmsRecipientResult(
              contactName: contact.name,
              phone: phone,
              outcome: WishprSmsRecipientOutcome.sentDirect,
              detailMessage: direct.message,
            ),
          );
          continue;
        }
        AppLog.d(
          'WishprSmsService: direct send failed for $phone: ${direct.message}',
        );
      }

      final launch = await _launcher.openSmsCompose(
        normalizedPhone: phone,
        messageBody: messageBody,
      );
      results.add(
        WishprSmsRecipientResult(
          contactName: contact.name,
          phone: phone,
          outcome: launch.opened
              ? WishprSmsRecipientOutcome.fallbackComposer
              : WishprSmsRecipientOutcome.failed,
          detailMessage: launch.opened
              ? 'Opened SMS composer (fallback).'
              : (launch.errorMessage ?? 'Composer could not be opened.'),
        ),
      );
    }

    return results;
  }

  Future<({bool ok, String message})> _tryAndroidDirectSms(
    String phone,
    String body,
  ) async {
    try {
      final ok = await _androidSmsChannel.invokeMethod<bool>(
        'sendDirectSms',
        <String, String>{'phone': phone, 'body': body},
      );
      if (ok == true) {
        return (ok: true, message: 'SMS queued via device (direct send).');
      }
      return (ok: false, message: 'Direct send returned false.');
    } on PlatformException catch (e) {
      return (
        ok: false,
        message: e.message?.isNotEmpty == true ? e.message! : e.code,
      );
    } catch (e, st) {
      AppLog.e('WishprSmsService direct SMS', e, st);
      return (ok: false, message: 'Direct send error: $e');
    }
  }
}
