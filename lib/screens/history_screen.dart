import 'package:flutter/material.dart';

import '../services/current_user_id.dart';
import '../services/firestore_error_message.dart';
import '../services/trigger_events_repository.dart';
import '../theme/wishpr_constants.dart';
import '../widgets/firestore_list_state.dart';
import '../widgets/signed_out_placeholder.dart';
import '../widgets/trigger_card.dart';
import 'trigger_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  TriggerEventsRepository? _eventsRepo;
  int _retryKey = 0;

  TriggerEventsRepository get _repo => _eventsRepo ??= TriggerEventsRepository();

  void _showGuardModeTip() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guard Mode'),
        content: const Text(
          'Open the Home tab and use Start Listening when you want Wishpr to '
          'watch for your secret phrases. When something matches, actions run and '
          'an entry appears here. Use Test Trigger to try the flow without speaking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uid = currentWishprUid();

    if (uid == null) {
      return const SignedOutPlaceholder();
    }

    return StreamBuilder(
      key: ValueKey(_retryKey),
      stream: _repo.watchTriggerEvents(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const FirestoreLoadingView(
            title: 'Loading history…',
            subtitle: 'Fetching your safety events.',
          );
        }

        if (snapshot.hasError) {
          return FirestoreErrorView(
            message: firestoreErrorMessage(snapshot.error),
            onRetry: () => setState(() => _retryKey++),
          );
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return FirestoreEmptyView(
            title: WishprFirestoreCopy.noHistoryTitle,
            body: WishprFirestoreCopy.noHistoryBody,
            icon: Icons.history_rounded,
            secondaryActionLabel: 'How does history fill up?',
            onSecondaryAction: _showGuardModeTip,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            WishprLayout.screenPaddingH,
            8,
            WishprLayout.screenPaddingH,
            WishprLayout.screenPaddingV,
          ),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final item = events[i];
            return TriggerCard(
              trigger: item,
              theme: theme,
              cs: cs,
              onOpenDetail: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => TriggerDetailScreen(trigger: item),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
