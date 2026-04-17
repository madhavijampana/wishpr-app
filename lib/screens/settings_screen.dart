import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_config.dart';
import '../platform/wishpr_permission_support.dart';
import '../platform/wishpr_platform.dart';
import '../platform/wishpr_platform_user_copy.dart';
import '../services/auth_service.dart';
import '../services/current_user_id.dart';
import '../services/debug_mode_controller.dart';
import '../services/firestore_error_message.dart';
import '../services/permission_service.dart';
import '../services/trigger_events_repository.dart';
import '../theme/wishpr_constants.dart';
import '../widgets/permission_rationale_dialog.dart';
import '../widgets/wishpr_feedback.dart';
import 'about_wishpr_screen.dart';
import 'legal_disclaimer_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  static const _permissionRows = <_PermissionRow>[
    _PermissionRow(
      kind: WishprPermission.microphone,
      title: 'Microphone Permission',
      icon: Icons.mic_rounded,
    ),
    _PermissionRow(
      kind: WishprPermission.locationWhenInUse,
      title: 'Location Permission',
      icon: Icons.location_on_rounded,
    ),
    _PermissionRow(
      kind: WishprPermission.notification,
      title: 'Notifications',
      icon: Icons.notifications_active_rounded,
    ),
    _PermissionRow(
      kind: WishprPermission.smsSend,
      title: 'SMS sending',
      icon: Icons.sms_rounded,
    ),
  ];

  Iterable<_PermissionRow> get _visiblePermissionRows => _permissionRows.where(
        (r) => WishprPermissionSupport.isManageableInSettings(r.kind),
      );

  final PermissionService _permissionService = const PermissionService();

  final Map<WishprPermission, PermissionStatus> _statuses = {};
  String _appVersion = '—';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionStatuses();
    _loadPackageInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(DebugModeController.instance.hydrate(currentWishprUid()));
    });
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${info.version} (${info.buildNumber})';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _appVersion = AppConfig.versionLabel);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStatuses();
    }
  }

  Future<void> _refreshPermissionStatuses() async {
    final next = <WishprPermission, PermissionStatus>{};
    for (final row in _visiblePermissionRows) {
      next[row.kind] = await _permissionService.status(row.kind);
    }
    if (mounted) {
      setState(() {
        _statuses
          ..clear()
          ..addAll(next);
      });
    }
  }

  Future<void> _onPermissionTap(WishprPermission kind) async {
    final current = _statuses[kind] ?? await _permissionService.status(kind);
    if (!mounted) return;

    if (current == PermissionStatus.permanentlyDenied) {
      await _permissionService.openAppSettingsPage();
      await _refreshPermissionStatuses();
      return;
    }

    if (_permissionService.isAllowed(current)) {
      await _permissionService.openAppSettingsPage();
      await _refreshPermissionStatuses();
      return;
    }

    if (kind == WishprPermission.microphone) {
      final go = await showMicrophonePermissionRationaleDialog(context);
      if (!go || !mounted) return;
    } else if (kind == WishprPermission.locationWhenInUse) {
      final go = await showLocationPermissionRationaleDialog(context);
      if (!go || !mounted) return;
    }

    await _permissionService.request(kind);
    await _refreshPermissionStatuses();
  }

  Future<void> _debugSampleTrigger() async {
    final uid = currentWishprUid();
    if (uid == null) {
      if (!mounted) return;
      WishprFeedback.info(context, 'Sign in to save a sample event.');
      return;
    }
    try {
      await TriggerEventsRepository().addSampleTestTrigger(uid);
      if (!mounted) return;
      WishprFeedback.success(
        context,
        'Sample trigger saved — open History to review.',
      );
    } catch (e) {
      if (!mounted) return;
      WishprFeedback.error(context, firestoreErrorMessage(e));
    }
  }

  Future<void> _confirmSignOut() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You’ll need to sign in again to use phrases, contacts, and Guard Mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (go != true || !mounted) return;

    try {
      await AuthService().signOut();
    } catch (_) {
      if (mounted) {
        WishprFeedback.error(
          context,
          'Could not sign out. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WishprLayout.settingsPaddingH,
        8,
        WishprLayout.settingsPaddingH,
        WishprLayout.screenPaddingV,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                WishprPlatformUserCopy.settingsDeviceSectionTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                WishprPlatformUserCopy.settingsDeviceBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
        ..._visiblePermissionRows.map((row) {
          final st = _statuses[row.kind];
          final statusLine = st == null
              ? 'Checking…'
              : _permissionService.statusLabel(st);
          final subtitleText = row.kind == WishprPermission.smsSend &&
                  WishprPlatform.isAndroid
              ? '$statusLine · Optional: may allow SMS without opening your SMS app first.'
              : statusLine;

          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(WishprLayout.iconTileRadius),
                  ),
                  child: Icon(row.icon, color: cs.primary),
                ),
                title: Text(
                  WishprPlatform.isAndroid && row.kind == WishprPermission.smsSend
                      ? '${row.title} (Android)'
                      : row.title,
                ),
                subtitle: Text(
                  subtitleText,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
                onTap: () => _onPermissionTap(row.kind),
              ),
              Divider(
                height: 1,
                indent: 72,
                color: cs.outline.withValues(alpha: 0.2),
              ),
            ],
          );
        }),
        ValueListenableBuilder<bool>(
          valueListenable: DebugModeController.instance,
          builder: (context, dev, _) {
            final uid = currentWishprUid();
            return SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              secondary: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(WishprLayout.iconTileRadius),
                ),
                child: Icon(Icons.developer_mode_outlined, color: cs.primary),
              ),
              title: const Text('Developer mode'),
              subtitle: Text(
                uid == null
                    ? 'Sign in to change this setting.'
                    : 'Shows Guard diagnostics, live transcripts, and raw errors.',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
              value: dev,
              onChanged: uid == null
                  ? null
                  : (v) async {
                      await DebugModeController.instance.setEnabled(uid, v);
                    },
            );
          },
        ),
        Divider(
          height: 1,
          indent: 72,
          color: cs.outline.withValues(alpha: 0.2),
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(WishprLayout.iconTileRadius),
            ),
            child: Icon(Icons.info_outline_rounded, color: cs.primary),
          ),
          title: const Text('App version'),
          subtitle: Text(
            _appVersion,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Divider(height: 1, indent: 72, color: cs.outline.withValues(alpha: 0.2)),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(WishprLayout.iconTileRadius),
            ),
            child: Icon(Icons.policy_outlined, color: cs.primary),
          ),
          title: const Text('Privacy Policy'),
          subtitle: Text(
            'Data we collect, how it’s used, sharing, and permissions',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const PrivacyPolicyScreen(),
              ),
            );
          },
        ),
        Divider(height: 1, indent: 72, color: cs.outline.withValues(alpha: 0.2)),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(WishprLayout.iconTileRadius),
            ),
            child: Icon(Icons.gavel_rounded, color: cs.primary),
          ),
          title: const Text('Safety & legal'),
          subtitle: Text(
            'Assistive tool, listening limits, device differences',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const LegalDisclaimerScreen(),
              ),
            );
          },
        ),
        Divider(height: 1, indent: 72, color: cs.outline.withValues(alpha: 0.2)),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(WishprLayout.iconTileRadius),
            ),
            child: Icon(Icons.favorite_outline_rounded, color: cs.primary),
          ),
          title: const Text('About Wishpr'),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const AboutWishprScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(WishprLayout.iconTileRadius),
            ),
            child: Icon(Icons.bug_report_outlined, color: cs.outline),
          ),
          title: const Text('Debug: sample trigger event'),
          subtitle: Text(
            'Writes a test-only history row (no SMS / location).',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          onTap: _debugSampleTrigger,
        ),
        Divider(height: 1, indent: 72, color: cs.outline.withValues(alpha: 0.2)),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(WishprLayout.iconTileRadius),
            ),
            child: Icon(Icons.logout_rounded, color: cs.error),
          ),
          title: Text(
            'Sign out',
            style: TextStyle(
              color: cs.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: _confirmSignOut,
        ),
      ],
    );
  }
}

class _PermissionRow {
  const _PermissionRow({
    required this.kind,
    required this.title,
    required this.icon,
  });

  final WishprPermission kind;
  final String title;
  final IconData icon;
}
