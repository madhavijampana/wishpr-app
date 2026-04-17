/// User-facing copy for Guard Mode (non-developer mode).
abstract final class GuardUserMessages {
  static const tapStartWhenReady =
      'Tap Start listening when you want Wishpr to watch for your phrase.';
  static const starting = 'Starting…';
  static const stopping = 'Stopping…';
  static const listening = 'Listening…';
  static const processingHeard = 'Processing what we heard…';
  static const couldNotHearClearly =
      'Could not hear clearly. Try speaking closer to the microphone, or stop and start again.';
  static const triggerNotMatched =
      'That didn’t match a secret phrase. You can keep speaking or adjust your phrase in Phrases.';
  static const cooldownBriefPause =
      'A trigger just ran — brief pause before another to avoid repeats.';
  static const speechRecognitionProblem =
      'Couldn’t use speech recognition. Check the microphone and try again.';
  static const speechNetworkProblem =
      'Speech recognition needs a working internet connection on this device. Check your network and try again.';
  static const phrasesLoadProblem =
      'Couldn’t load your phrases. Check your connection and try again.';
  static const speechEngineUnavailable =
      'Speech recognition isn’t available on this device right now. Check microphone access and try again.';
  static const signInToUse = 'Sign in to use Guard Mode.';
  static const eventSaveFailed =
      'Couldn’t save the safety event. Check your connection and try again.';
}
