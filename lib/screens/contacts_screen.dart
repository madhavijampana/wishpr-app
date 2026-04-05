import 'package:flutter/material.dart';

import '../services/contacts_repository.dart';
import '../services/current_user_id.dart';
import '../services/firestore_error_message.dart';
import '../theme/wishpr_constants.dart';
import '../widgets/contact_card.dart';
import '../widgets/firestore_list_state.dart';
import '../widgets/signed_out_placeholder.dart';
import '../widgets/wishpr_feedback.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  ContactsRepository? _contactsRepo;
  int _retryKey = 0;

  ContactsRepository get _repo => _contactsRepo ??= ContactsRepository();

  Future<void> _openAddContact() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const AddContactScreen(),
      ),
    );
    if (!mounted) return;
    if (added == true) {
      WishprFeedback.success(
        context,
        'Contact saved. They can be reached when a phrase triggers.',
      );
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
              onPressed: uid == null ? null : _openAddContact,
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: const Text('Add Contact'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: uid == null
              ? const SignedOutPlaceholder()
              : StreamBuilder(
                  key: ValueKey(_retryKey),
                  stream: _repo.watchContacts(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const FirestoreLoadingView(
                        title: 'Loading contacts…',
                        subtitle: 'Fetching your trusted contacts.',
                      );
                    }

                    if (snapshot.hasError) {
                      return FirestoreErrorView(
                        message: firestoreErrorMessage(snapshot.error),
                        onRetry: () => setState(() => _retryKey++),
                      );
                    }

                    final contacts = snapshot.data ?? [];
                    if (contacts.isEmpty) {
                      return FirestoreEmptyView(
                        title: WishprFirestoreCopy.noContactsTitle,
                        body: WishprFirestoreCopy.noContactsBody,
                        icon: Icons.people_rounded,
                        primaryActionLabel: 'Add a trusted contact',
                        onPrimaryAction: _openAddContact,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        WishprLayout.screenPaddingH,
                        0,
                        WishprLayout.screenPaddingH,
                        WishprLayout.screenPaddingV,
                      ),
                      itemCount: contacts.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ContactCard(
                            contact: contacts[i],
                            cs: cs,
                            theme: theme,
                            onTap: () async {
                              final updated = await Navigator.of(context)
                                  .push<bool>(
                                MaterialPageRoute<bool>(
                                  builder: (context) => AddContactScreen(
                                    existing: contacts[i],
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              if (updated == true) {
                                WishprFeedback.success(
                                  context,
                                  'Contact updated.',
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
