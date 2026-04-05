import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/app_log.dart';
import 'firebase_options.dart';
import 'theme/wishpr_constants.dart';
import 'theme/wishpr_theme.dart';
import 'widgets/auth_gate.dart';
import 'widgets/wishpr_bootstrap_error.dart';
import 'widgets/wishpr_splash_view.dart';

/// Root widget: Firebase init, branded splash, then [AuthGate].
class WishprApp extends StatefulWidget {
  const WishprApp({super.key});

  @override
  State<WishprApp> createState() => _WishprAppState();
}

class _WishprAppState extends State<WishprApp> {
  bool _initializing = true;
  bool _initFailed = false;
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    setState(() {
      _initializing = true;
      _initFailed = false;
      _failureMessage = null;
    });
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLog.d('Firebase initialized');
    } catch (e, st) {
      AppLog.e('Firebase.initializeApp failed', e, st);
      if (mounted) {
        setState(() {
          _initFailed = true;
          _failureMessage = e.toString();
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _initializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: WishprStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: WishprTheme.dark,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_initializing) {
      return const WishprSplashView(
        message: 'Starting services…',
      );
    }
    if (_initFailed) {
      return WishprBootstrapError(
        message: _failureMessage != null && _failureMessage!.isNotEmpty
            ? 'Check your network and Firebase configuration.\n\n$_failureMessage'
            : 'Check your network and Firebase configuration, then try again.',
        onRetry: _initializeFirebase,
      );
    }
    return const AuthGate();
  }
}
