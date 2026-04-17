import 'package:flutter/material.dart';

/// Short in-app explanation before the OS permission sheet (Play / App Store friendly).
Future<bool> showPermissionRationaleDialog(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            body,
            style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Microphone — used before [Permission.microphone] request.
Future<bool> showMicrophonePermissionRationaleDialog(BuildContext context) {
  return showPermissionRationaleDialog(
    context,
    title: 'Microphone access',
    body:
        'Wishpr uses the microphone to detect your safety trigger phrases when '
        'Guard Mode is listening. Speech is processed on your device to match '
        'what you say to your saved phrases — only while you have a session active.',
  );
}

/// Location — used before [Permission.locationWhenInUse] request.
Future<bool> showLocationPermissionRationaleDialog(BuildContext context) {
  return showPermissionRationaleDialog(
    context,
    title: 'Location access',
    body:
        'Wishpr uses your location to share it during emergency alerts when a '
        'phrase triggers, if you enabled that action — so trusted contacts can '
        'see where you are when you need help.',
  );
}

/// Device contacts — use before [Permission.contacts] if you add address-book import.
Future<bool> showContactsPermissionRationaleDialog(BuildContext context) {
  return showPermissionRationaleDialog(
    context,
    title: 'Contacts access',
    body:
        'Wishpr needs access to your contacts only if you choose to pick people '
        'from your address book. That makes it easier to notify trusted contacts. '
        'You can always add names and phone numbers manually without this access.',
  );
}

/// One-time education: trusted contacts vs device address book (no OS permission).
Future<void> showTrustedContactsEducationDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Trusted contacts'),
        content: SingleChildScrollView(
          child: Text(
            'Add people you trust with their phone numbers so Wishpr can notify them '
            '(for example by SMS or call) when a safety phrase triggers.\n\n'
            'Wishpr does not read your device address book unless you later use a '
            'contact-import feature and allow contacts access when the app asks.',
            style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      );
    },
  );
}
