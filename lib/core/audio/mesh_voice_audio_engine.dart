import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'jitter_buffer.dart';
import 'opus/opus_decoder.dart';
import 'opus/opus_encoder.dart';

abstract class AudioCaptureSource {
  Stream<Int16List> get frames;
  Future<void> start();
  Future<void> stop();
  Future<void> setMicEnabled(bool enabled);
}

abstract class AudioPlaybackSink {
  Future<void> start();
  Future<void> stop();
  Future<void> push(Int16List pcm);
}

class MeshVoiceAudioEngine {
  final AudioCaptureSource capture;
  final AudioPlaybackSink playback;
  final int sampleRate;
  final int channels;
  final int frameSamples; // = sampleRate * frameMs / 1000

  final OpusEncoder _encoder;
  final OpusDecoder _decoder;
  final JitterBuffer _jb;

  final _outboundCtrl = StreamController<Uint8List>.broadcast();
  StreamSubscription<Int16List>? _captureSub;
  Timer? _drainTimer;

  MeshVoiceAudioEngine({
    required this.capture,
    required this.playback,
    this.sampleRate = 16000,
    this.channels = 1,
    int frameMs = 20,
    int bitrate = 24000,
  })  : frameSamples = sampleRate * frameMs ~/ 1000,
        _encoder = OpusEncoder(sampleRate: sampleRate, channels: channels, bitrate: bitrate),
        _decoder = OpusDecoder(sampleRate: sampleRate, channels: channels),
        _jb = JitterBuffer(targetDepthFrames: 4);

  Stream<Uint8List> get outbound => _outboundCtrl.stream;

  Future<void> start() async {
    debugPrint('[MeshVoiceAudioEngine] start() begin');
    await capture.start();
    debugPrint('[MeshVoiceAudioEngine] capture.start() returned');
    await playback.start();
    debugPrint('[MeshVoiceAudioEngine] playback.start() returned');
    int captureFrames = 0;
    int encodeErrors = 0;
    int lastReportAt = DateTime.now().millisecondsSinceEpoch;
    _captureSub = capture.frames.listen((pcm) {
      captureFrames++;
      try {
        final encoded = _encoder.encode(pcm);
        _outboundCtrl.add(encoded);
      } catch (e) {
        encodeErrors++;
        if (encodeErrors <= 3) {
          debugPrint('[MeshVoiceAudioEngine] encode error: $e (pcm.len=${pcm.length})');
        }
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastReportAt > 1000) {
        debugPrint('[MeshVoiceAudioEngine] captureFrames=$captureFrames encodeErrors=$encodeErrors');
        lastReportAt = now;
      }
    }, onError: (e, st) {
      debugPrint('[MeshVoiceAudioEngine] capture stream error: $e\n$st');
    });
    debugPrint('[MeshVoiceAudioEngine] subscribed to capture.frames');
    int drainPulls = 0;
    int drainPlayed = 0;
    int drainEmpty = 0;
    int drainErrors = 0;
    int lastDrainReport = DateTime.now().millisecondsSinceEpoch;
    // Drain jitter buffer at frame cadence.
    _drainTimer = Timer.periodic(Duration(milliseconds: 1000 * frameSamples ~/ sampleRate), (_) {
      drainPulls++;
      final next = _jb.pull();
      final now = DateTime.now().millisecondsSinceEpoch;
      if (next == null) {
        drainEmpty++;
        if (now - lastDrainReport > 1000) {
          debugPrint('[MeshVoiceAudioEngine] drainPulls=$drainPulls drainEmpty=$drainEmpty drainPlayed=$drainPlayed drainErrors=$drainErrors');
          lastDrainReport = now;
        }
        return;
      }
      try {
        final pcm = next.kind == JitterFrameKind.payload && next.payload != null
            ? _decoder.decode(next.payload!, frameSize: frameSamples)
            : (next.kind == JitterFrameKind.plc
                ? _decoder.decode(Uint8List(0), frameSize: frameSamples) // PLC
                : Int16List(frameSamples)); // silence
        playback.push(pcm);
        drainPlayed++;
      } catch (e) {
        drainErrors++;
        if (drainErrors <= 3) {
          debugPrint('[MeshVoiceAudioEngine] decode/push error: $e');
        }
      }
      if (now - lastDrainReport > 1000) {
        debugPrint('[MeshVoiceAudioEngine] drainPulls=$drainPulls drainEmpty=$drainEmpty drainPlayed=$drainPlayed drainErrors=$drainErrors');
        lastDrainReport = now;
      }
    });
    debugPrint('[MeshVoiceAudioEngine] drain timer armed');
  }

  /// Inject an inbound encoded Opus packet identified by [seq].
  void inbound({required int seq, required Uint8List payload}) {
    _jb.push(seq: seq, payload: payload);
  }

  Future<void> stop() async {
    _drainTimer?.cancel();
    await _captureSub?.cancel();
    await capture.stop();
    await playback.stop();
    _encoder.dispose();
    _decoder.dispose();
    await _outboundCtrl.close();
  }
}
