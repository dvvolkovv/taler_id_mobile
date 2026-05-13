import 'dart:typed_data';

import 'group_mesh_voice_audio_engine.dart';
import 'mesh_voice_audio_engine.dart'
    show AudioCaptureSource, AudioPlaybackSink;
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

/// Build a [GroupMeshVoiceAudioEngine] backed by the platform audio plugin.
/// Use this from [GroupMeshCallService.audioEngineFactory] in DI so each
/// call gets a fresh engine + microphone session.
GroupMeshVoiceAudioEngine defaultGroupMeshVoiceAudioEngine() {
  // 320 samples = 20 ms @ 16 kHz — matches the 1-on-1 default.
  const sampleRate = 16000;
  const frameMs = 20;
  const frameSamples = sampleRate * frameMs ~/ 1000;
  return GroupMeshVoiceAudioEngine(
    capture: _CaptureAdapter(AudioCapture()),
    playback: _PlaybackAdapter(AudioPlayback()),
    encoderFactory: () => FfiGroupMeshOpusEncoder(
      sampleRate: sampleRate,
      channels: 1,
      bitrate: 24000,
    ),
    decoderFactory: () => FfiGroupMeshOpusDecoder(
      sampleRate: sampleRate,
      channels: 1,
      frameSamples: frameSamples,
    ),
    sampleRate: sampleRate,
    frameMs: frameMs,
  );
}
