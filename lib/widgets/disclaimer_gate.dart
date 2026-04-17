import 'package:flutter/material.dart';

import '../screens/disclaimer_screen.dart';
import '../services/disclaimer_prefs.dart';
import 'wishpr_splash_view.dart';

/// Runs before auth and main shell: requires safety disclaimer acceptance once
/// per device ([DisclaimerPrefs]).
class DisclaimerGate extends StatefulWidget {
  const DisclaimerGate({super.key, required this.child});

  /// Shown when [DisclaimerPrefs.isAccepted] is true (e.g. [AuthGate]).
  final Widget child;

  @override
  State<DisclaimerGate> createState() => _DisclaimerGateState();
}

class _DisclaimerGateState extends State<DisclaimerGate> {
  bool? _accepted;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ok = await DisclaimerPrefs.isAccepted();
    if (!mounted) return;
    setState(() => _accepted = ok);
  }

  void _onAccepted() {
    setState(() => _accepted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_accepted == null) {
      return const WishprSplashView(
        message: 'Loading…',
      );
    }
    if (_accepted == false) {
      return DisclaimerScreen(onAccepted: _onAccepted);
    }
    return widget.child;
  }
}
