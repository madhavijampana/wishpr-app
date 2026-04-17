import 'package:flutter/material.dart';

import '../theme/wishpr_constants.dart';

/// In-app privacy policy summary; replace the contact placeholder before public launch.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _contactEmailPlaceholder = 'privacy@example.com';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WishprLayout.screenPaddingH,
          16,
          WishprLayout.screenPaddingH,
          WishprLayout.screenPaddingV,
        ),
        children: [
          Text(
            'How Wishpr handles your information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This policy describes what we collect, why we use it, and your permissions. '
            'It is a summary for in-app use; publish a full legal policy before wide release.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            cs: cs,
            icon: Icons.folder_open_outlined,
            title: 'Data we collect',
            body:
                'Depending on how you use Wishpr, the app may process or store:\n\n'
                '• Microphone audio while Guard Mode or related features are actively listening, '
                'for phrase detection.\n\n'
                '• Contacts you choose as trusted contacts, so alerts can reach them.\n\n'
                '• Location when you enable location-based features (for example sharing where '
                'you are during a trigger), subject to your settings and permissions.\n\n'
                '• Trigger logs — records of phrase matches and actions that ran — so you can '
                'review history and improve your setup.',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            cs: cs,
            icon: Icons.bolt_outlined,
            title: 'How we use data',
            body:
                'Information is used only to run the app’s safety features:\n\n'
                '• Sending alerts and notifications you configure (such as SMS or calls).\n\n'
                '• Phrase detection and matching when you use listening features.\n\n'
                '• Core app functionality — syncing phrases, contacts, and history with your '
                'account, and keeping the experience reliable.',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            cs: cs,
            icon: Icons.handshake_outlined,
            title: 'Data sharing',
            body:
                'We do not sell your personal data. Information is used to provide Wishpr’s '
                'features (for example, your chosen cloud backend for sign-in and storage). '
                'It is not shared for unrelated marketing. Third-party services you interact '
                'with (such as your carrier for SMS) operate under their own policies.',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            cs: cs,
            icon: Icons.admin_panel_settings_outlined,
            title: 'Permissions',
            body:
                'Wishpr asks for permissions only when needed. Microphone access is for speech '
                'recognition while you use Guard Mode (or similar flows). Contacts access helps '
                'you pick trusted contacts. Location is optional and used when you enable '
                'features that include place information. You can review or revoke permissions '
                'in your device settings; some features may not work without them.',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            cs: cs,
            icon: Icons.emergency_outlined,
            title: 'Not a replacement for emergency services',
            body:
                'Wishpr is a safety assistance tool. It does not replace emergency services, '
                'professional responders, or medical care. Always contact your local emergency '
                'number when you or someone else is in immediate danger.',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            cs: cs,
            icon: Icons.mail_outline_rounded,
            title: 'Contact us',
            body:
                'Questions about privacy or this policy? Reach us at the address below '
                '(placeholder — replace before production):\n',
            trailing: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectableText(
                _contactEmailPlaceholder,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: cs.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.cs,
    required this.icon,
    required this.title,
    required this.body,
    this.trailing,
  });

  final ColorScheme cs;
  final IconData icon;
  final String title;
  final String body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: cs.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: cs.onSurface.withValues(alpha: 0.88),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
