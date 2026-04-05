import '../models/firestore/contact_document.dart';

/// Picks a trusted contact for device SMS / dial flows.
///
/// Contacts are expected in **oldest-first** order (first saved = primary).
abstract final class TrustedContactSelector {
  /// All dialable contacts in [preferredIds] order (for multi-recipient SMS).
  static List<ContactDocument> orderedDialablePreferred(
    List<ContactDocument> contacts,
    List<String> orderedIds,
  ) {
    if (orderedIds.isEmpty) return const [];
    final byId = {for (final c in contacts) c.id: c};
    final out = <ContactDocument>[];
    for (final id in orderedIds) {
      final c = byId[id];
      if (c != null && _normalizePhone(c.phone) != null) out.add(c);
    }
    return out;
  }

  /// First dialable contact in [preferredIds] order, or `null` if none.
  static ContactDocument? firstDialablePreferred(
    List<ContactDocument> contacts,
    List<String> preferredIds,
  ) {
    if (preferredIds.isEmpty) return null;
    final byId = {for (final c in contacts) c.id: c};
    for (final id in preferredIds) {
      final c = byId[id];
      if (c != null && _normalizePhone(c.phone) != null) return c;
    }
    return null;
  }

  /// First contact with a dialable number whose [ContactDocument.alertMethod]
  /// is `SMS` or `Both`; otherwise the first dialable contact.
  ///
  /// When [preferredContactIds] is non-empty, uses that order instead (phrase
  /// configuration); user-selected recipients need not match alertMethod.
  /// Recipients in UI order; falls back to legacy single primary when ids empty.
  static List<ContactDocument> smsRecipientsOrdered(
    List<ContactDocument> contacts,
    List<String> preferredIds,
  ) {
    final list = orderedDialablePreferred(contacts, preferredIds);
    if (list.isNotEmpty) return list;
    final one = forSms(contacts, preferredContactIds: const []);
    return one == null ? const [] : [one];
  }

  static ContactDocument? forSms(
    List<ContactDocument> contacts, {
    List<String> preferredContactIds = const [],
  }) {
    if (preferredContactIds.isNotEmpty) {
      return firstDialablePreferred(contacts, preferredContactIds);
    }
    final dialable = _withDialablePhone(contacts);
    if (dialable.isEmpty) return null;
    for (final c in dialable) {
      if (c.alertMethod == 'SMS' || c.alertMethod == 'Both') return c;
    }
    return dialable.first;
  }

  /// First contact with a dialable number whose [ContactDocument.alertMethod]
  /// is `Call` or `Both`; otherwise the first dialable contact.
  ///
  /// When [preferredContactIds] is non-empty, uses that order instead.
  static ContactDocument? forCall(
    List<ContactDocument> contacts, {
    List<String> preferredContactIds = const [],
  }) {
    if (preferredContactIds.isNotEmpty) {
      return firstDialablePreferred(contacts, preferredContactIds);
    }
    final dialable = _withDialablePhone(contacts);
    if (dialable.isEmpty) return null;
    for (final c in dialable) {
      if (c.alertMethod == 'Call' || c.alertMethod == 'Both') return c;
    }
    return dialable.first;
  }

  static List<ContactDocument> _withDialablePhone(
    List<ContactDocument> contacts,
  ) {
    return contacts.where((c) => _normalizePhone(c.phone) != null).toList();
  }

  /// Returns digits with optional leading `+`, or `null` if unusable.
  static String? normalizePhoneForDevice(String raw) => _normalizePhone(raw);

  static String? _normalizePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final buf = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final ch = trimmed[i];
      if (ch == '+' && buf.isEmpty) {
        buf.write(ch);
      } else {
        final code = ch.codeUnitAt(0);
        if (code >= 48 && code <= 57) buf.write(ch);
      }
    }
    final s = buf.toString();
    if (s.isEmpty || s == '+') return null;
    return s;
  }
}
