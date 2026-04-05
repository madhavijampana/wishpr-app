import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import 'auth_loading_scaffold.dart';
import 'post_auth_shell.dart';

/// Routes between auth and the main app based on [FirebaseAuth.authStateChanges].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthLoadingScaffold(
            title: 'Loading…',
            subtitle: 'Checking your session…',
          );
        }

        if (snapshot.hasError) {
          return const AuthLoadingScaffold(
            title: 'Sign-in check failed',
            subtitle:
                'Please restart the app. If this keeps happening, contact your test organizer.',
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return PostAuthShell(user: user);
        }

        return const LoginScreen();
      },
    );
  }
}
