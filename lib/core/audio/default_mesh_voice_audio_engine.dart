import 'dart:typed_data';

import 'mesh_voice_audio_engine.dart';
import 'platform/audio_capture.dart';
import 'platform/audio_playback.dart';

class _CaptureAdapter implements AudioCaptureSource {
  final AudioCapture _capture;
  _CaptureAdapter(this._capture);

  @override
  Stream<Int16List> get frames => _capture.frames;
  @override
  Future<void> start() => _capture.start();
  @override
  Future<void> stop() => _capture.stop();
  @override
  Future<void> setMicEnabled(bool enabled) => _capture.setMicEnabled(enabled);
}

class _PlaybackAdapter implements AudioPlaybackSink {
  final AudioPlayback _playback;
  _PlaybackAdapter(this._playback);

  @override
  Future<void> start() => _playback.start();
  @override
  Future<void> stop() => _playback.stop();
  @override
  Future<void> push(Int16List pcm) => _playback.push(pcm);
}

/// Build a [MeshVoiceAudioEngine] backed by the platform's
/// `AudioCapture` / `AudioPlayback` (Phase 3a). Use this from
/// [MeshVoiceService.audioEngineFactory] in DI so each call gets a
/// fresh engine + microphone session.
MeshVoiceAudioEngine defaultMeshVoiceAudioEngine() {
  return MeshVoiceAudioEngine(
    capture: _CaptureAdapter(AudioCapture()),
    playback: _PlaybackAdapter(AudioPlayback()),
  );
}
