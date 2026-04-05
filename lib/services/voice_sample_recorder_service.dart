import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../config/app_log.dart';
import '../models/voice_sample_meta.dart';

/// Records short clips for phrase voice-sample metadata (local files + duration).
class VoiceSampleRecorderService {
  VoiceSampleRecorderService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _activePath;
  DateTime? _startedAt;

  Future<bool> hasMicPermission() async {
    return _recorder.hasPermission();
  }

  Future<void> startRecordingToFile(String absolutePath) async {
    _startedAt = DateTime.now();
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: absolutePath,
    );
    _activePath = absolutePath;
  }

  Future<VoiceSampleMeta?> stopAndMeta({
    required String phraseId,
    required int sampleIndex,
  }) async {
    final path = _activePath;
    _activePath = null;
    final started = _startedAt;
    _startedAt = null;
    if (path == null) return null;
    try {
      await _recorder.stop();
      final file = File(path);
      if (!await file.exists()) return null;
      final durationSec = started != null
          ? DateTime.now().difference(started).inMilliseconds / 1000.0
          : 0.5;
      return VoiceSampleMeta(
        durationSec: durationSec.clamp(0.1, 120.0),
        recordedAt: DateTime.now().toUtc(),
        localFileName: '${phraseId}_$sampleIndex.m4a',
      );
    } catch (e, st) {
      AppLog.e('VoiceSampleRecorderService.stop', e, st);
      return null;
    }
  }

  Future<void> cancel() async {
    _activePath = null;
    _startedAt = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  static Future<String> sampleDirectoryForPhrase(String phraseId) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/wishpr_voice_samples/$phraseId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> nextRecordingPath(String phraseId, int index) async {
    final dir = await sampleDirectoryForPhrase(phraseId);
    return '$dir/sample_$index.m4a';
  }

  Future<void> disposeRecorder() async {
    await cancel();
    await _recorder.dispose();
  }
}
