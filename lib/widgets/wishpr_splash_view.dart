import 'package:flutter/material.dart';

import '../theme/wishpr_colors.dart';
import '../theme/wishpr_constants.dart';
import '../widgets/wishpr_wordmark.dart';

/// Full-screen branded splash while Firebase and the first frame initialize.
class WishprSplashView extends StatelessWidget {
  const WishprSplashView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WishprColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF140A1E),
              WishprColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const WishprWordmark(fontSize: 42),
                const SizedBox(height: 12),
                Text(
                  WishprStrings.tagline,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: WishprColors.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: WishprColors.primary.withValues(alpha: 0.9),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: WishprColors.onSurface.withValues(alpha: 0.45),
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
