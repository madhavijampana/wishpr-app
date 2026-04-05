import 'package:flutter/material.dart';

import '../theme/wishpr_constants.dart';

/// Safety and legal expectations for beta testers.
class LegalDisclaimerScreen extends StatelessWidget {
  const LegalDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & legal'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WishprLayout.screenPaddingH,
          16,
          WishprLayout.screenPaddingH,
          WishprLayout.screenPaddingV,
        ),
        children: [
          _SectionCard(
            cs: cs,
            icon: Icons.health_and_safety_outlined,
            title: 'Assistive safety tool',
            body:
                'Wishpr is an assistive tool to help you reach people you trust. It does not '
                'replace emergency services, medical care, or professional safety planning. '
                'Always use your best judgment and contact local emergency numbers when you '
                'are in immediate danger.',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            cs: cs,
            icon: Icons.mic_off_outlined,
            title: 'Listening only in Guard Mode',
            body:
                'This version of Wishpr does not support background or always-on listening. '
                'Speech recognition runs only when you start listening from Guard Mode on the '
                'Home screen and stops when you end the session or leave the flow.',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            cs: cs,
            icon: Icons.devices_other_rounded,
            title: 'Device and platform differences',
            body:
                'SMS, phone calls, location accuracy, and permissions behave differently on '
                'each phone and operating system. A phrase match may open system apps (such as '
                'the SMS composer or dialer) rather than sending messages automatically. '
                'Results are not guaranteed.',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            cs: cs,
            icon: Icons.gavel_rounded,
            title: 'No warranty',
            body:
                'Wishpr is provided "as is" during beta. The team is not liable for outcomes '
                'from use or non-use of the app. For questions about liability or compliance '
                'in your region, consult a qualified professional.',
          ),
          const SizedBox(height: 24),
          Text(
            'By using Wishpr beta, you understand these limitations. If anything is unclear, '
            'reach out through your test program channel before relying on the app in a crisis.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
              height: 1.45,
              fontStyle: FontStyle.italic,
            ),
          ),
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
  });

  final ColorScheme cs;
  final IconData icon;
  final String title;
  final String body;

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
          ],
        ),
      ),
    );
  }
}
