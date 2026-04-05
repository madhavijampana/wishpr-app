import 'package:flutter/material.dart';

import '../models/firestore/contact_document.dart';
import '../services/contacts_repository.dart';
import '../services/current_user_id.dart';
import '../services/firestore_error_message.dart';
import '../theme/wishpr_constants.dart';
import '../utils/wishpr_validators.dart';
import '../widgets/wishpr_dropdown_field.dart';
import '../widgets/wishpr_form_bottom_bar.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key, this.existing});

  /// When set, screen edits this contact (update / delete).
  final ContactDocument? existing;

  static const List<String> alertMethods = [
    'SMS',
    'Call',
    'Both',
  ];

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  String _alertMethod = AddContactScreen.alertMethods.first;

  bool _saving = false;
  bool _deleting = false;
  String? _errorMessage;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _phoneController.text = e.phone;
      _relationshipController.text = e.relationship;
      if (AddContactScreen.alertMethods.contains(e.alertMethod)) {
        _alertMethod = e.alertMethod;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final relationship = _relationshipController.text.trim();

    final uid = currentWishprUid();
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to save.')),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ContactsRepository();
      if (_isEdit) {
        final doc = ContactDocument(
          id: widget.existing!.id,
          name: name,
          phone: phone,
          relationship: relationship,
          alertMethod: _alertMethod,
          createdAt: widget.existing!.createdAt,
        );
        await repo.updateContact(
          uid: uid,
          contactId: widget.existing!.id,
          contact: doc,
        );
      } else {
        await repo.addContact(
          uid: uid,
          name: name,
          phone: phone,
          relationship: relationship,
          alertMethod: _alertMethod,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = firestoreErrorMessage(e);
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final e = widget.existing;
    if (e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text(
          'Remove ${e.name.isEmpty ? 'this contact' : e.name} from trusted contacts? '
          'Phrases that use this contact may need updating.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final uid = currentWishprUid();
    if (uid == null) return;

    setState(() => _deleting = true);
    try {
      await ContactsRepository().deleteContact(uid: uid, contactId: e.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(firestoreErrorMessage(err))),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Contact details' : 'Add Contact'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete contact',
              onPressed: _saving || _deleting ? null : _confirmDelete,
              icon: _deleting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                WishprLayout.screenPaddingH,
                8,
                WishprLayout.screenPaddingH,
                WishprLayout.screenPaddingV,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      _ContactFormError(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Jordan Lee',
                      ),
                      validator: WishprValidators.fullName,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+1 (555) 000-0000',
                      ),
                      validator: WishprValidators.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _relationshipController,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        hintText: 'Partner, sibling, friend…',
                      ),
                      validator: WishprValidators.relationship,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    WishprDropdownField<String>(
                      labelText: 'Preferred Alert Method',
                      value: _alertMethod,
                      items: AddContactScreen.alertMethods,
                      itemLabel: (m) => m,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _alertMethod = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          WishprFormBottomBar(
            label: _saving ? 'Saving…' : (_isEdit ? 'Save changes' : 'Save'),
            onPressed: _saving || _deleting ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _ContactFormError extends StatelessWidget {
  const _ContactFormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(WishprLayout.fieldRadius),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: cs.error, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.error,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
