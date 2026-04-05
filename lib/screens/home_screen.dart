import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/wishpr_constants.dart';
import '../widgets/activity_tile.dart';
import '../widgets/wishpr_wordmark.dart';
import 'guard_mode_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              WishprLayout.screenPaddingH,
              12,
              WishprLayout.screenPaddingH,
              8,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const WishprWordmark(),
                  const SizedBox(height: 10),
                  Text(
                    WishprStrings.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const GuardModeScreen(),
                  const SizedBox(height: 28),
                  Text(
                    'Recent Activity',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: cs.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: WishprLayout.screenPaddingH),
            sliver: SliverList.separated(
              itemCount: SampleData.recentActivity.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                return ActivityTile(item: SampleData.recentActivity[i]);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
