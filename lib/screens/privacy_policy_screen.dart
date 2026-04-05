import 'package:flutter/material.dart';

import '../theme/wishpr_constants.dart';

/// In-app privacy overview for beta testers; link a hosted policy before public launch.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
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
            'Your data in Wishpr',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Wishpr is designed to support personal safety. During beta, the app may store:',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          _Bullet(cs, 'Account email and profile information you provide.'),
          _Bullet(cs, 'Secret phrases, trusted contacts, and safety preferences you save.'),
          _Bullet(cs, 'Records of when phrases matched and which actions ran (history).'),
          const SizedBox(height: 20),
          Text(
            'Speech and Guard Mode',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guard Mode uses the microphone only while you have started listening in the app. '
            'Wishpr does not perform background listening in this version.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Before public release',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We plan to publish a full privacy policy, clearer retention rules, and tools to '
            'export or delete your data. This screen is a summary for beta testers only and '
            'is not legal advice.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.cs, this.text);

  final ColorScheme cs;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: cs.primary, fontSize: 18)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: cs.onSurface.withValues(alpha: 0.88),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
