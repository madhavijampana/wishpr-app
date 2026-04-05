import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/permission_service.dart';

/// Friendly prompt when Guard Mode needs the microphone for future speech listening.
Future<void> showMicrophonePermissionDialog({
  required BuildContext context,
  required PermissionService permissionService,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Microphone access'),
        content: const Text(
          'Guard Mode will listen for your secret phrases using speech recognition '
          '(coming soon). Wishpr needs microphone access to do that safely and only '
          'when you start a session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final status =
                  await permissionService.request(WishprPermission.microphone);
              if (!context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              if (permissionService.isAllowed(status)) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Microphone enabled. Speech listening will connect in a future update.',
                    ),
                  ),
                );
              } else if (status == PermissionStatus.permanentlyDenied) {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Microphone is blocked in system settings. You can enable it there.',
                    ),
                    action: SnackBarAction(
                      label: 'Settings',
                      onPressed: () => permissionService.openAppSettingsPage(),
                    ),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Microphone permission was not granted. You can try again from Settings.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Allow microphone'),
          ),
        ],
      );
    },
  );
}
