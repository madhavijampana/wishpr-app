import 'dart:async';

import 'package:flutter/material.dart';

import '../models/firestore/contact_document.dart';
import '../models/firestore/phrase_document.dart';
import '../models/phrase_matching_mode.dart';
import '../models/voice_sample_meta.dart';
import '../services/contacts_repository.dart';
import '../services/current_user_id.dart';
import '../services/firestore_error_message.dart';
import '../services/phrases_repository.dart';
import '../services/sms_template_helper.dart';
import '../services/voice_sample_recorder_service.dart';
import '../theme/wishpr_constants.dart';
import '../utils/wishpr_validators.dart';
import '../widgets/wishpr_dropdown_field.dart';
import '../widgets/wishpr_form_bottom_bar.dart';

class AddPhraseScreen extends StatefulWidget {
  const AddPhraseScreen({super.key, this.existing});

  /// When set, screen edits this phrase (update / delete).
  final PhraseDocument? existing;

  static const List<String> categories = [
    'Emergency',
    'Family',
    'Social',
    'Custom',
  ];

  @override
  State<AddPhraseScreen> createState() => _AddPhraseScreenState();
}

class _AddPhraseScreenState extends State<AddPhraseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _secretController = TextEditingController();
  final _smsTemplateController = TextEditingController();
  String _category = AddPhraseScreen.categories.first;
  PhraseMatchingMode _matchMode = PhraseMatchingMode.flexible;
  bool _active = true;

  bool _sendSms = false;
  bool _shareLocation = false;
  bool _callContact = false;
  bool _startRecording = false;

  final Set<String> _smsContactPick = {};
  final Set<String> _callContactPick = {};

  bool _saving = false;
  bool _deleting = false;
  String? _errorMessage;

  bool get _isEdit => widget.existing != null;

  ContactsRepository? _contactsRepo;

  ContactsRepository get _contactsRepoInst =>
      _contactsRepo ??= ContactsRepository();

  final VoiceSampleRecorderService _voiceRecorder = VoiceSampleRecorderService();
  final List<VoiceSampleMeta> _voiceSamples = [];
  bool _voiceRecording = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _labelController.text = e.label;
      _secretController.text = e.secretPhrase;
      if (AddPhraseScreen.categories.contains(e.category)) {
        _category = e.category;
      }
      _active = e.active;
      _sendSms = e.sendSms;
      _shareLocation = e.shareLocation;
      _callContact = e.callContact;
      _startRecording = e.startRecording;
      _smsContactPick.addAll(e.smsContactIds);
      _callContactPick.addAll(e.callContactIds);
      _matchMode = e.matchMode;
      _smsTemplateController.text = e.smsTemplate;
      _voiceSamples.addAll(e.voiceSamples);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _secretController.dispose();
    _smsTemplateController.dispose();
    unawaited(_voiceRecorder.disposeRecorder());
    super.dispose();
  }

  Future<void> _toggleVoiceRecording() async {
    final e = widget.existing;
    if (e == null || e.id.isEmpty) return;
    if (_voiceRecording) {
      setState(() => _voiceRecording = false);
      final meta = await _voiceRecorder.stopAndMeta(
        phraseId: e.id,
        sampleIndex: _voiceSamples.length,
      );
      if (!mounted) return;
      if (meta != null) {
        setState(() => _voiceSamples.add(meta));
      }
      return;
    }
    if (_voiceSamples.length >= 3) return;
    final permitted = await _voiceRecorder.hasMicPermission();
    if (!permitted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record a sample.'),
          ),
        );
      }
      return;
    }
    final path = await VoiceSampleRecorderService.nextRecordingPath(
      e.id,
      _voiceSamples.length,
    );
    await _voiceRecorder.startRecordingToFile(path);
    if (mounted) setState(() => _voiceRecording = true);
  }

  void _removeVoiceSampleAt(int index) {
    if (index < 0 || index >= _voiceSamples.length) return;
    setState(() => _voiceSamples.removeAt(index));
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final label = _labelController.text.trim();
    final secret = _secretController.text.trim();

    final uid = currentWishprUid();
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to save.')),
        );
      }
      return;
    }

    List<String> orderedIds(
      List<ContactDocument> contacts,
      Set<String> pick,
    ) {
      return contacts.where((c) => pick.contains(c.id)).map((c) => c.id).toList();
    }

    setState(() => _saving = true);
    try {
      final contacts =
          await _contactsRepoInst.fetchContactsOnceNewestFirst(uid);
      final smsIds = _sendSms ? orderedIds(contacts, _smsContactPick) : <String>[];
      final callIds =
          _callContact ? orderedIds(contacts, _callContactPick) : <String>[];

      final repo = PhrasesRepository();
      if (_isEdit) {
        final e = widget.existing!;
        final doc = PhraseDocument(
          id: e.id,
          label: label,
          secretPhrase: secret,
          category: _category,
          active: _active,
          sendSms: _sendSms,
          shareLocation: _shareLocation,
          callContact: _callContact,
          startRecording: _startRecording,
          createdAt: e.createdAt,
          smsContactIds: smsIds,
          callContactIds: callIds,
          matchMode: _matchMode,
          smsTemplate: _smsTemplateController.text.trim(),
          voiceSamples: List<VoiceSampleMeta>.from(_voiceSamples),
        );
        await repo.updatePhrase(uid: uid, phraseId: e.id, phrase: doc);
      } else {
        await repo.addPhrase(
          uid: uid,
          label: label,
          secretPhrase: secret,
          category: _category,
          active: _active,
          sendSms: _sendSms,
          shareLocation: _shareLocation,
          callContact: _callContact,
          startRecording: _startRecording,
          smsContactIds: smsIds,
          callContactIds: callIds,
          matchMode: _matchMode,
          smsTemplate: _smsTemplateController.text.trim(),
          voiceSamples: const [],
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
        title: const Text('Delete phrase?'),
        content: Text(
          'Remove "${e.label.isEmpty ? e.secretPhrase : e.label}"? '
          'Guard Mode will no longer listen for it.',
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
      await PhrasesRepository().deletePhrase(uid: uid, phraseId: e.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (err) {
      if (mounted) {
        setState(() => _errorMessage = firestoreErrorMessage(err));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uid = currentWishprUid();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Phrase details' : 'Add Phrase'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete phrase',
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
                      _InlineFormError(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _labelController,
                      textCapitalization: TextCapitalization.words,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Phrase Label',
                        hintText: 'e.g. Midnight oak',
                      ),
                      validator: WishprValidators.phraseLabel,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _secretController,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Secret Phrase Text',
                        hintText: 'Exact words you will say aloud',
                      ),
                      maxLines: 2,
                      validator: WishprValidators.secretPhrase,
                      textInputAction: TextInputAction.next,
                    ),
                  const SizedBox(height: 16),
                  WishprDropdownField<String>(
                    labelText: 'Category',
                    value: _category,
                    items: AddPhraseScreen.categories,
                    itemLabel: (c) => c,
                    onChanged:
                        _saving ? null : (v) => setState(() => _category = v),
                  ),
                  const SizedBox(height: 16),
                  WishprDropdownField<PhraseMatchingMode>(
                    labelText: 'Phrase matching mode',
                    value: _matchMode,
                    items: PhraseMatchingMode.values.toList(),
                    itemLabel: (m) => m.uiLabel,
                    onChanged: _saving || _deleting
                        ? null
                        : (v) => setState(() => _matchMode = v),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    subtitle: Text(
                      'When off, this phrase will not trigger actions.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    value: _active,
                    onChanged: _saving ? null : (v) => setState(() => _active = v),
                  ),
                  const SizedBox(height: 20),
                  _FormSectionTitle(
                    title: 'Trigger Actions',
                    subtitle:
                        'Choose what happens when this phrase is recognized.',
                  ),
                  const SizedBox(height: 12),
                  _TriggerActionsCard(
                    enabled: !_saving && !_deleting,
                    sendSms: _sendSms,
                    shareLocation: _shareLocation,
                    callContact: _callContact,
                    startRecording: _startRecording,
                    onSendSms: (v) => setState(() => _sendSms = v),
                    onShareLocation: (v) => setState(() => _shareLocation = v),
                    onCallContact: (v) => setState(() => _callContact = v),
                    onStartRecording: (v) => setState(() => _startRecording = v),
                  ),
                  if (_sendSms) ...[
                    const SizedBox(height: 20),
                    _FormSectionTitle(
                      title: 'SMS message',
                      subtitle:
                          'Placeholders: ${SmsTemplateHelper.phraseLabelKey}, '
                          '${SmsTemplateHelper.phraseTextKey}, '
                          '${SmsTemplateHelper.locationLinkKey}. '
                          'If empty, default is used.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _smsTemplateController,
                      enabled: !_saving && !_deleting,
                      maxLines: 5,
                      minLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Custom SMS text',
                        hintText: SmsTemplateHelper.defaultTemplate,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'On Android, Wishpr tries to send SMS in the background when '
                      'permission is granted; many devices still require the composer. '
                      'Automatic send is best-effort only.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.tertiary.withValues(alpha: 0.95),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (uid != null && (_sendSms || _callContact)) ...[
                    const SizedBox(height: 24),
                    _FormSectionTitle(
                      title: 'Trusted contacts for actions',
                      subtitle: _sendSms && _callContact
                          ? 'Choose who receives SMS and who is called when this phrase triggers.'
                          : _sendSms
                              ? 'Choose one or more contacts for the SMS action (first valid number is used first).'
                              : 'Choose one or more contacts for the call action (first valid number is used first).',
                    ),
                    const SizedBox(height: 12),
                    _PhraseContactPickCard(
                      uid: uid,
                      contactsRepo: _contactsRepoInst,
                      sendSms: _sendSms,
                      callContact: _callContact,
                      smsPick: _smsContactPick,
                      callPick: _callContactPick,
                      enabled: !_saving && !_deleting,
                      onSmsToggle: (contactId, selected) {
                        setState(() {
                          if (selected) {
                            _smsContactPick.add(contactId);
                          } else {
                            _smsContactPick.remove(contactId);
                          }
                        });
                      },
                      onCallToggle: (contactId, selected) {
                        setState(() {
                          if (selected) {
                            _callContactPick.add(contactId);
                          } else {
                            _callContactPick.remove(contactId);
                          }
                        });
                      },
                    ),
                  ],
                  if (_isEdit && widget.existing != null) ...[
                    const SizedBox(height: 24),
                    _FormSectionTitle(
                      title: 'Voice samples (optional)',
                      subtitle:
                          'Up to 3 short recordings — stored as metadata for future use. '
                          'No voice matching yet.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_voiceSamples.length} sample(s) saved',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_voiceSamples.length, (i) {
                      final s = _voiceSamples[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Sample ${i + 1} · ${s.durationSec.toStringAsFixed(1)}s',
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          onPressed: _saving || _deleting || _voiceRecording
                              ? null
                              : () => _removeVoiceSampleAt(i),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: _saving ||
                              _deleting ||
                              _voiceSamples.length >= 3
                          ? null
                          : _toggleVoiceRecording,
                      icon: Icon(
                        _voiceRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      ),
                      label: Text(
                        _voiceRecording ? 'Stop recording' : 'Record sample',
                      ),
                    ),
                  ],
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

class _InlineFormError extends StatelessWidget {
  const _InlineFormError({required this.message});

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

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: cs.onSurface.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.55),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _TriggerActionsCard extends StatelessWidget {
  const _TriggerActionsCard({
    required this.enabled,
    required this.sendSms,
    required this.shareLocation,
    required this.callContact,
    required this.startRecording,
    required this.onSendSms,
    required this.onShareLocation,
    required this.onCallContact,
    required this.onStartRecording,
  });

  final bool enabled;
  final bool sendSms;
  final bool shareLocation;
  final bool callContact;
  final bool startRecording;
  final ValueChanged<bool> onSendSms;
  final ValueChanged<bool> onShareLocation;
  final ValueChanged<bool> onCallContact;
  final ValueChanged<bool> onStartRecording;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('Send SMS'),
            value: sendSms,
            onChanged: enabled ? (v) => onSendSms(v ?? false) : null,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.15)),
          CheckboxListTile(
            title: const Text('Share Location'),
            value: shareLocation,
            onChanged: enabled ? (v) => onShareLocation(v ?? false) : null,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.15)),
          CheckboxListTile(
            title: const Text('Call Contact'),
            value: callContact,
            onChanged: enabled ? (v) => onCallContact(v ?? false) : null,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.15)),
          CheckboxListTile(
            title: const Text('Start Recording'),
            value: startRecording,
            onChanged: enabled ? (v) => onStartRecording(v ?? false) : null,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}

class _PhraseContactPickCard extends StatelessWidget {
  const _PhraseContactPickCard({
    required this.uid,
    required this.contactsRepo,
    required this.sendSms,
    required this.callContact,
    required this.smsPick,
    required this.callPick,
    required this.enabled,
    required this.onSmsToggle,
    required this.onCallToggle,
  });

  final String uid;
  final ContactsRepository contactsRepo;
  final bool sendSms;
  final bool callContact;
  final Set<String> smsPick;
  final Set<String> callPick;
  final bool enabled;
  final void Function(String contactId, bool selected) onSmsToggle;
  final void Function(String contactId, bool selected) onCallToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return StreamBuilder<List<ContactDocument>>(
      stream: contactsRepo.watchContacts(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Could not load contacts: ${snapshot.error}',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
          );
        }
        final contacts = snapshot.data ?? [];
        if (contacts.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add trusted contacts first, then return here to assign them '
                'to SMS or call actions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ),
          );
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sendSms) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Send SMS',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...contacts.map((c) {
                  return CheckboxListTile(
                    title: Text(c.name.isEmpty ? 'Unnamed' : c.name),
                    subtitle: Text(
                      c.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    value: smsPick.contains(c.id),
                    onChanged: enabled
                        ? (v) => onSmsToggle(c.id, v ?? false)
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
                if (callContact) Divider(height: 1, color: cs.outline.withValues(alpha: 0.15)),
              ],
              if (callContact) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Call contact',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...contacts.map((c) {
                  return CheckboxListTile(
                    title: Text(c.name.isEmpty ? 'Unnamed' : c.name),
                    subtitle: Text(
                      c.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    value: callPick.contains(c.id),
                    onChanged: enabled
                        ? (v) => onCallToggle(c.id, v ?? false)
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
