import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/disclaimer_prefs.dart';
import '../theme/wishpr_constants.dart';

/// Mandatory first-run safety disclaimer with scrollable copy and accept / exit actions.
class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key, required this.onAccepted});

  /// Called after [DisclaimerPrefs.markAccepted] succeeds.
  final VoidCallback onAccepted;

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _busy = false;

  static const String _bodyText = '''
Wishpr is a safety assistance tool only. It is designed to support you alongside your own judgment and other resources — not to replace them.

The app does not guarantee your protection, the success of any alert, or that emergency services or other parties will respond. Network conditions, device settings, permissions, and third-party services are outside our control.

Voice and phrase detection use speech recognition on your device. Recognition can fail, mishear words, miss phrases, or respond incorrectly in noisy environments, with accents, or when you are unwell or distressed. Do not rely solely on the app to detect danger or to contact help.

Always call your local emergency number (for example, 911, 999, 112, or the number for your region) when you or someone else is in immediate danger or needs emergency services. No feature in this app is a substitute for professional emergency response.

By continuing, you confirm that you understand these limitations and will use Wishpr as a supplement — not your only safeguard — in situations that affect your safety.''';

  Future<void> _onContinue() async {
    setState(() => _busy = true);
    try {
      await DisclaimerPrefs.markAccepted();
      if (!mounted) return;
      widget.onAccepted();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onExit() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            WishprLayout.screenPaddingH,
            16,
            WishprLayout.screenPaddingH,
            WishprLayout.screenPaddingV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Important Safety Disclaimer',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please read carefully before using Wishpr.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(WishprLayout.cardRadius),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      child: Text(
                        _bodyText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.55,
                          color: cs.onSurface.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _onContinue,
                child: _busy
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Text('I Understand & Continue'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _busy ? null : _onExit,
                child: const Text('Exit App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
