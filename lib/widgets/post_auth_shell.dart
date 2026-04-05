import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/onboarding_screen.dart';
import '../screens/wishpr_shell.dart';
import '../services/onboarding_prefs.dart';
import 'auth_loading_scaffold.dart';

/// After Firebase sign-in: onboarding once per account, then main shell.
class PostAuthShell extends StatefulWidget {
  const PostAuthShell({super.key, required this.user});

  final User user;

  @override
  State<PostAuthShell> createState() => _PostAuthShellState();
}

class _PostAuthShellState extends State<PostAuthShell> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _loadOnboardingFlag();
  }

  Future<void> _loadOnboardingFlag() async {
    final done = await OnboardingPrefs.isComplete(widget.user.uid);
    if (mounted) setState(() => _onboardingDone = done);
  }

  void _completeOnboarding() {
    setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const AuthLoadingScaffold(
        title: 'Preparing Wishpr…',
        subtitle: 'Almost there.',
      );
    }

    if (_onboardingDone == false) {
      return OnboardingScreen(
        userId: widget.user.uid,
        onFinished: _completeOnboarding,
      );
    }

    return const WishprShell();
  }
}
