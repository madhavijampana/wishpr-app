import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../theme/wishpr_constants.dart';

class AboutWishprScreen extends StatefulWidget {
  const AboutWishprScreen({super.key});

  @override
  State<AboutWishprScreen> createState() => _AboutWishprScreenState();
}

class _AboutWishprScreenState extends State<AboutWishprScreen> {
  String _versionLine = 'Loading…';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _versionLine =
              '${info.version} (${info.buildNumber}) · ${AppConfig.releaseChannel}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _versionLine =
              '${AppConfig.marketingVersionPlaceholder} · ${AppConfig.releaseChannel}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Wishpr'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WishprLayout.screenPaddingH,
          20,
          WishprLayout.screenPaddingH,
          WishprLayout.screenPaddingV,
        ),
        children: [
          Text(
            WishprStrings.appName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            WishprStrings.tagline,
            style: theme.textTheme.titleSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _versionLine,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Wishpr helps you link spoken phrases to trusted actions — so the people '
            'you choose can be notified when you need support.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Text(
            'This is a beta build. Features and reliability will improve based on tester feedback. '
            'Thank you for helping shape Wishpr.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.78),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
