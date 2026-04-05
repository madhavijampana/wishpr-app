import 'package:url_launcher/url_launcher.dart';

/// Outcome of handing off to the system SMS or phone UI.
class CommLaunchOutcome {
  const CommLaunchOutcome({required this.opened, this.errorMessage});

  final bool opened;
  final String? errorMessage;
}

/// Opens the platform SMS composer and phone dialer via [url_launcher].
class WishprCommLauncherService {
  const WishprCommLauncherService();

  /// Opens the default SMS app with [messageBody] prefilled.
  Future<CommLaunchOutcome> openSmsCompose({
    required String normalizedPhone,
    required String messageBody,
  }) async {
    final path = normalizedPhone.trim();
    if (path.isEmpty) {
      return const CommLaunchOutcome(
        opened: false,
        errorMessage: 'Phone number is missing.',
      );
    }

    final uri = Uri(
      scheme: 'sms',
      path: path,
      queryParameters: {'body': messageBody},
    );

    try {
      if (!await canLaunchUrl(uri)) {
        return const CommLaunchOutcome(
          opened: false,
          errorMessage: 'No SMS app is available on this device.',
        );
      }
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return CommLaunchOutcome(
        opened: ok,
        errorMessage: ok ? null : 'Could not open the SMS composer.',
      );
    } catch (e) {
      return CommLaunchOutcome(
        opened: false,
        errorMessage: 'SMS could not be opened: $e',
      );
    }
  }

  /// Opens the dialer with [normalizedPhone] (use [LaunchMode.platformDefault]
  /// on some platforms so `tel:` does not require CALL_PHONE permission).
  Future<CommLaunchOutcome> openTelDialer(String normalizedPhone) async {
    final path = normalizedPhone.trim();
    if (path.isEmpty) {
      return const CommLaunchOutcome(
        opened: false,
        errorMessage: 'Phone number is missing.',
      );
    }

    final uri = Uri(scheme: 'tel', path: path);

    try {
      if (!await canLaunchUrl(uri)) {
        return const CommLaunchOutcome(
          opened: false,
          errorMessage: 'No phone app is available on this device.',
        );
      }
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return CommLaunchOutcome(
        opened: ok,
        errorMessage: ok ? null : 'Could not open the phone dialer.',
      );
    } catch (e) {
      return CommLaunchOutcome(
        opened: false,
        errorMessage: 'Dialer could not be opened: $e',
      );
    }
  }
}
