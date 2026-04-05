import 'package:flutter/material.dart';

import '../services/onboarding_prefs.dart';
import '../theme/wishpr_constants.dart';
import '../widgets/wishpr_wordmark.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.userId,
    required this.onFinished,
  });

  final String userId;
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      icon: Icons.waving_hand_rounded,
      title: 'Welcome to Wishpr',
      body:
          'Wishpr turns your own words into a safety plan. You stay in control — nothing runs in the background until you start Guard Mode.',
    ),
    _OnboardingPageData(
      icon: Icons.format_quote_rounded,
      title: 'Secret phrases',
      body:
          'Create short phrases only you would say. When Guard Mode hears a match, Wishpr can run the actions you chose — like texting a friend or sharing your location.',
    ),
    _OnboardingPageData(
      icon: Icons.people_rounded,
      title: 'Trusted contacts',
      body:
          'Add people you trust with their phone numbers. They’re used when a phrase triggers SMS or call actions. You can set how each person prefers to be reached.',
    ),
    _OnboardingPageData(
      icon: Icons.shield_moon_rounded,
      title: 'Guard Mode',
      body:
          'From Home, tap Start Listening when you want protection active. Speak normally; Wishpr listens for your phrases, then runs your playbook. Tap Stop when you’re done.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await OnboardingPrefs.markComplete(widget.userId);
    if (mounted) widget.onFinished();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const WishprWordmark(fontSize: 22),
                  const Spacer(),
                  TextButton(
                    onPressed: _complete,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      WishprLayout.screenPaddingH,
                      16,
                      WishprLayout.screenPaddingH,
                      8,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                cs.primary.withValues(alpha: 0.35),
                                cs.secondary.withValues(alpha: 0.25),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(p.icon, size: 48, color: cs.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.72),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WishprLayout.screenPaddingH,
                0,
                WishprLayout.screenPaddingH,
                20,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i == _page
                                ? cs.primary
                                : cs.outline.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _page == _pages.length - 1 ? 'Get started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
