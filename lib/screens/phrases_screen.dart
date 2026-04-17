import 'package:flutter/material.dart';

import '../services/current_user_id.dart';
import '../services/firestore_error_message.dart';
import '../services/phrases_repository.dart';
import '../theme/wishpr_constants.dart';
import '../widgets/firestore_list_state.dart';
import '../widgets/phrase_card.dart';
import '../widgets/signed_out_placeholder.dart';
import '../widgets/wishpr_feedback.dart';
import 'add_phrase_screen.dart';

class PhrasesScreen extends StatefulWidget {
  const PhrasesScreen({super.key});

  @override
  State<PhrasesScreen> createState() => _PhrasesScreenState();
}

class _PhrasesScreenState extends State<PhrasesScreen> {
  PhrasesRepository? _phrasesRepo;
  int _retryKey = 0;

  PhrasesRepository get _repo => _phrasesRepo ??= PhrasesRepository();

  Future<void> _openAddPhrase() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const AddPhraseScreen(),
      ),
    );
    if (!mounted) return;
    if (added == true) {
      WishprFeedback.success(context, 'Phrase saved. It’s ready for Guard Mode.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uid = currentWishprUid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            WishprLayout.screenPaddingH,
            8,
            WishprLayout.screenPaddingH,
            0,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: uid == null ? null : _openAddPhrase,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Phrase'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: uid == null
              ? const SignedOutPlaceholder()
              : StreamBuilder(
                  key: ValueKey(_retryKey),
                  stream: _repo.watchPhrases(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const FirestoreLoadingView(
                        title: 'Loading phrases…',
                        subtitle: 'Fetching your secret phrases from the cloud.',
                      );
                    }

                    if (snapshot.hasError) {
                      return FirestoreErrorView(
                        message: firestoreErrorMessage(snapshot.error),
                        onRetry: () => setState(() => _retryKey++),
                      );
                    }

                    final phrases = snapshot.data ?? [];
                    if (phrases.isEmpty) {
                      return FirestoreEmptyView(
                        title: WishprFirestoreCopy.noPhrasesTitle,
                        body: WishprFirestoreCopy.noPhrasesBody,
                        icon: Icons.format_quote_rounded,
                        primaryActionLabel: 'Add your first phrase',
                        onPrimaryAction: _openAddPhrase,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        WishprLayout.screenPaddingH,
                        0,
                        WishprLayout.screenPaddingH,
                        WishprLayout.screenPaddingV,
                      ),
                      itemCount: phrases.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PhraseCard(
                            phrase: phrases[i],
                            cs: cs,
                            theme: theme,
                            onTap: () async {
                              final updated = await Navigator.of(context)
                                  .push<bool>(
                                MaterialPageRoute<bool>(
                                  builder: (context) => AddPhraseScreen(
                                    existing: phrases[i],
                                  ),
                                ),
                              );
                              if (!context.mounted) return;
                              if (updated == true) {
                                WishprFeedback.success(
                                  context,
                                  'Phrase updated.',
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
