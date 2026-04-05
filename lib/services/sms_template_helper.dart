import '../models/firestore/phrase_document.dart';
import '../models/firestore/trigger_location_snapshot.dart';

/// Expands `{phrase_label}`, `{phrase_text}`, `{location_link}` in SMS templates.
abstract final class SmsTemplateHelper {
  static const String defaultTemplate =
      'I need help. My location: {location_link}';

  static const phraseLabelKey = '{phrase_label}';
  static const phraseTextKey = '{phrase_text}';
  static const locationLinkKey = '{location_link}';

  static String locationLinkFromSnapshot(TriggerLocationSnapshot? snapshot) {
    if (snapshot == null) return '';
    final q = '${snapshot.latitude},${snapshot.longitude}';
    return 'https://www.google.com/maps/search/?api=1&query=$q';
  }

  /// Resolves template: empty/whitespace uses [defaultTemplate].
  static String resolve({
    required PhraseDocument phrase,
    TriggerLocationSnapshot? locationSnapshot,
  }) {
    var raw = phrase.smsTemplate.trim();
    if (raw.isEmpty) {
      raw = defaultTemplate;
    }

    final link = locationLinkFromSnapshot(locationSnapshot);
    final linkOrHint =
        link.isEmpty ? '(no location captured yet)' : link;
    return raw
        .replaceAll(phraseLabelKey, phrase.label)
        .replaceAll(phraseTextKey, phrase.secretPhrase)
        .replaceAll(locationLinkKey, linkOrHint);
  }
}
