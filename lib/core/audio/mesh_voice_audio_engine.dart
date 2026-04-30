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
    await capture.start();
    await playback.start();
    _captureSub = capture.frames.listen((pcm) {
      try {
        final encoded = _encoder.encode(pcm);
        _outboundCtrl.add(encoded);
      } catch (e) {
        debugPrint('[MeshVoiceAudioEngine] encode error: $e (pcm.len=${pcm.length})');
      }
    }, onError: (e, st) {
      debugPrint('[MeshVoiceAudioEngine] capture stream error: $e');
    });
    // Drain jitter buffer at frame cadence.
    _drainTimer = Timer.periodic(Duration(milliseconds: 1000 * frameSamples ~/ sampleRate), (_) {
      final next = _jb.pull();
      if (next == null) return;
      try {
        final pcm = next.kind == JitterFrameKind.payload && next.payload != null
            ? _decoder.decode(next.payload!, frameSize: frameSamples)
            : (next.kind == JitterFrameKind.plc
                ? _decoder.decode(Uint8List(0), frameSize: frameSamples) // PLC
                : Int16List(frameSamples)); // silence
        playback.push(pcm);
      } catch (e) {
        debugPrint('[MeshVoiceAudioEngine] decode/push error: $e');
      }
    });
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
