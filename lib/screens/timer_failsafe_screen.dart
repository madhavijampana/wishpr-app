import 'package:flutter/material.dart';

import '../models/firestore/phrase_document.dart';
import '../services/current_user_id.dart';
import '../services/firestore_error_message.dart';
import '../services/phrase_match_helper.dart';
import '../services/phrases_repository.dart';
import '../services/safety_prefs.dart';
import '../services/trigger_events_repository.dart';
import '../theme/wishpr_constants.dart';
import '../widgets/signed_out_placeholder.dart';
import '../widgets/wishpr_feedback.dart';
import '../widgets/wishpr_safety_host.dart';

/// Timer Fail-Safe: countdown, I’m Safe cancel, Firestore + actions on expiry.
class TimerFailsafeScreen extends StatefulWidget {
  const TimerFailsafeScreen({super.key});

  @override
  State<TimerFailsafeScreen> createState() => _TimerFailsafeScreenState();
}

class _TimerFailsafeScreenState extends State<TimerFailsafeScreen> {
  final PhrasesRepository _phrasesRepo = PhrasesRepository();
  final TriggerEventsRepository _triggerRepo = TriggerEventsRepository();

  List<PhraseDocument> _phrases = [];
  bool _loading = true;
  String? _selectedPhraseId;
  final TextEditingController _customMinutes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customMinutes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = currentWishprUid();
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final list = await _phrasesRepo.fetchPhrasesOnce(uid);
      final active = list
          .where((p) => p.active && p.secretPhrase.trim().isNotEmpty)
          .toList();
      var saved = await SafetyPrefs.getSafetyPhraseId(uid);
      if (saved != null && !active.any((p) => p.id == saved)) {
        saved = null;
      }
      if (!mounted) return;
      setState(() {
        _phrases = active;
        _selectedPhraseId =
            saved ?? (active.isNotEmpty ? active.first.id : null);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        WishprFeedback.error(context, firestoreErrorMessage(e));
      }
    }
  }

  Future<void> _persistPhraseId(String uid, String id) async {
    await SafetyPrefs.setSafetyPhraseId(uid, id);
  }

  PhraseDocument? get _selectedPhrase {
    if (_selectedPhraseId == null) return null;
    for (final p in _phrases) {
      if (p.id == _selectedPhraseId) return p;
    }
    return null;
  }

  Duration? _parseArmDuration() {
    final raw = _customMinutes.text.trim();
    if (raw.isNotEmpty) {
      final m = int.tryParse(raw);
      if (m != null && m > 0 && m <= 24 * 60) {
        return Duration(minutes: m);
      }
      return null;
    }
    return null;
  }

  void _armPreset(BuildContext context, Duration d) {
    final scope = WishprSafetyScope.maybeOf(context);
    if (scope == null) return;
    scope.timer.arm(d);
    WishprFeedback.success(context, 'Timer Fail-Safe armed.');
  }

  Future<void> _onImSafe(BuildContext context) async {
    final uid = currentWishprUid();
    final scope = WishprSafetyScope.maybeOf(context);
    if (uid == null || scope == null) return;

    final phrase = _selectedPhrase;
    scope.timer.cancelImSafe();

    try {
      await _triggerRepo.logTimerCancelled(
        uid: uid,
        phraseLabel: phrase?.label ?? 'Timer Fail-Safe',
        phraseText: phrase?.secretPhrase ?? '',
        phraseId: phrase?.id ?? '',
        actionSummary: phrase != null
            ? PhraseMatchHelper.buildActionSummary(phrase)
            : '',
      );
    } catch (e) {
      if (context.mounted) {
        WishprFeedback.error(context, firestoreErrorMessage(e));
      }
      return;
    }

    if (context.mounted) {
      WishprFeedback.success(context, 'Timer cancelled — you’re safe.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uid = currentWishprUid();

    if (uid == null) {
      return const Scaffold(
        body: SignedOutPlaceholder(),
      );
    }

    final scope = WishprSafetyScope.maybeOf(context);
    if (scope == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Timer Fail-Safe')),
        body: const Center(
          child: Text('Safety services unavailable.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Fail-Safe'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                WishprLayout.screenPaddingH,
                16,
                WishprLayout.screenPaddingH,
                32,
              ),
              children: [
                Text(
                  'If you don’t tap I’m Safe before the timer ends, Wishpr runs '
                  'the same safety actions as your selected phrase.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                if (_phrases.isEmpty)
                  Text(
                    'Add at least one active secret phrase with actions (Phrases tab).',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.error,
                    ),
                  )
                else ...[
                  Text(
                    'Safety phrase',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PhraseDropdown(
                    key: ValueKey(
                      '${_phrases.length}_$_selectedPhraseId',
                    ),
                    phraseIds: _phrases.map((p) => p.id).toList(),
                    phraseLabel: (id) {
                      final p = _phrases.firstWhere((e) => e.id == id);
                      return p.label.isNotEmpty ? p.label : p.secretPhrase;
                    },
                    selectedId: _phrases.any((p) => p.id == _selectedPhraseId)
                        ? _selectedPhraseId!
                        : _phrases.first.id,
                    onSelected: (v) async {
                      setState(() => _selectedPhraseId = v);
                      await _persistPhraseId(uid, v);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedPhrase != null) ...[
                    Text(
                      'Actions',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PhraseMatchHelper.buildActionSummary(_selectedPhrase!),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contacts for SMS / call follow your phrase’s trusted contact picks.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                Text(
                  'Duration',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DurChip(
                      label: '5 min',
                      onTap: _phrases.isEmpty
                          ? null
                          : () => _armPreset(context, const Duration(minutes: 5)),
                    ),
                    _DurChip(
                      label: '10 min',
                      onTap: _phrases.isEmpty
                          ? null
                          : () =>
                              _armPreset(context, const Duration(minutes: 10)),
                    ),
                    _DurChip(
                      label: '15 min',
                      onTap: _phrases.isEmpty
                          ? null
                          : () =>
                              _armPreset(context, const Duration(minutes: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customMinutes,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Custom minutes (1–1440)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _phrases.isEmpty
                      ? null
                      : () {
                          final d = _parseArmDuration();
                          if (d == null) {
                            WishprFeedback.info(
                              context,
                              'Enter a valid number of minutes (1–1440), or use a preset.',
                            );
                            return;
                          }
                          _armPreset(context, d);
                        },
                  icon: const Icon(Icons.timer_rounded),
                  label: const Text('Start custom timer'),
                ),
                const SizedBox(height: 28),
                ListenableBuilder(
                  listenable: scope.timer,
                  builder: (context, _) {
                    final t = scope.timer;
                    if (!t.isRunning && !t.isHandlingDeadline) {
                      return Text(
                        'Status: idle',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      );
                    }
                    if (t.isHandlingDeadline) {
                      return Text(
                        'Status: triggered — running safety actions…',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }
                    final r = t.remaining;
                    final h = r.inHours;
                    final m = r.inMinutes.remainder(60);
                    final s = r.inSeconds.remainder(60);
                    final timeStr = h > 0
                        ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
                        : '${r.inMinutes}:${s.toString().padLeft(2, '0')}';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (t.inWarningWindow)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cs.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.error.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: cs.error),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Less than 30 seconds — tap I’m Safe if you’re okay.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          'Timer running',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeStr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.tonalIcon(
                          onPressed: () => _onImSafe(context),
                          icon: const Icon(Icons.verified_user_rounded),
                          label: const Text('I’m Safe — cancel timer'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _DurChip extends StatelessWidget {
  const _DurChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _PhraseDropdown extends StatelessWidget {
  const _PhraseDropdown({
    super.key,
    required this.phraseIds,
    required this.phraseLabel,
    required this.selectedId,
    required this.onSelected,
  });

  final List<String> phraseIds;
  final String Function(String id) phraseLabel;
  final String selectedId;
  final void Function(String id) onSelected;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width -
        2 * WishprLayout.screenPaddingH;
    return DropdownMenu<String>(
      width: w,
      initialSelection: selectedId,
      label: const Text('Selected phrase'),
      onSelected: (v) {
        if (v != null) onSelected(v);
      },
      dropdownMenuEntries: [
        for (final id in phraseIds)
          DropdownMenuEntry<String>(
            value: id,
            label: phraseLabel(id),
          ),
      ],
    );
  }
}
