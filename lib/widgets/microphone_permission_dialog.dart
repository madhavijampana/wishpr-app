import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/permission_service.dart';
import 'permission_rationale_dialog.dart';

/// Explains microphone use, then requests permission (rationale before OS dialog).
Future<void> showMicrophonePermissionDialog({
  required BuildContext context,
  required PermissionService permissionService,
}) async {
  final go = await showMicrophonePermissionRationaleDialog(context);
  if (!go || !context.mounted) return;

  final status =
      await permissionService.request(WishprPermission.microphone);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  if (permissionService.isAllowed(status)) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Microphone enabled. You can start Guard Mode when you’re ready.'),
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
}
