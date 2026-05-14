import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:taler_id_mobile/core/audio/group_mesh_voice_mixer.dart';
import 'package:taler_id_mobile/core/audio/mesh_voice_audio_engine.dart'
    show AudioCaptureSource, AudioPlaybackSink;
import 'package:taler_id_mobile/core/audio/opus/opus_decoder.dart';
import 'package:taler_id_mobile/core/audio/opus/opus_encoder.dart';

/// Test-injectable opus encoder interface.
abstract class GroupMeshOpusEncoder {
  Uint8List encode(Int16List pcm);
  void dispose();
}

/// Test-injectable opus decoder interface. [frameSize] is passed at decode
/// time so a single decoder instance can serve fixed-frame audio.
abstract class GroupMeshOpusDecoder {
  Int16List decode(Uint8List payload);
  void dispose();
}

/// Production adapter — wraps the existing FFI [OpusEncoder].
class FfiGroupMeshOpusEncoder implements GroupMeshOpusEncoder {
  FfiGroupMeshOpusEncoder({
    int sampleRate = 16000,
    int channels = 1,
    int bitrate = 24000,
  }) : _impl = OpusEncoder(
          sampleRate: sampleRate,
          channels: channels,
          bitrate: bitrate,
        );
  final OpusEncoder _impl;
  @override
  Uint8List encode(Int16List pcm) => _impl.encode(pcm);
  @override
  void dispose() => _impl.dispose();
}

/// Production adapter — wraps the existing FFI [OpusDecoder]. The decoder
/// needs a frame size per call; we capture it at construction so the
/// abstract interface stays minimal.
class FfiGroupMeshOpusDecoder implements GroupMeshOpusDecoder {
  FfiGroupMeshOpusDecoder({
    int sampleRate = 16000,
    int channels = 1,
    required this.frameSamples,
  }) : _impl = OpusDecoder(sampleRate: sampleRate, channels: channels);
  final OpusDecoder _impl;
  final int frameSamples;
  @override
  Int16List decode(Uint8List payload) =>
      _impl.decode(payload, frameSize: frameSamples);
  @override
  void dispose() => _impl.dispose();
}

class _PeerSlot {
  _PeerSlot({required this.decoder});
  final GroupMeshOpusDecoder decoder;
  /// Small jitter buffer — out-of-order or bursty arrivals were chopping audio
  /// into prerývanýia because the previous "latestPcm slot" overwrote on burst
  /// and emitted silence on jitter. With a 3-frame FIFO at 20 ms each the
  /// playback tolerates ±60 ms of network jitter without dropouts.
  static const int maxBuffered = 3;
  final Queue<Int16List> jitter = Queue<Int16List>();
  int lastSeqAccepted = -1;
}

/// Multi-peer mesh voice audio engine.
///
/// Audio path:
///   mic → capture frames (Int16 PCM, [frameSamples] samples per 20 ms tick)
///     → opus encode (one shared encoder) → outbound stream.
///
/// Inbound: per-peer opus decode → per-peer latest-PCM slot. On each capture
/// tick the mixer reads each slot's latestPcm and writes the mix to playback.
///
/// Limitations (v1):
/// - No real jitter buffer: out-of-order or burst frames will drop. The 20 ms
///   capture cadence keeps it tolerable on a clean Wi-Fi; a per-peer jitter
///   buffer is a follow-up.
class GroupMeshVoiceAudioEngine {
  GroupMeshVoiceAudioEngine({
    required this.capture,
    required this.playback,
    required GroupMeshOpusEncoder Function() encoderFactory,
    required this.decoderFactory,
    this.sampleRate = 16000,
    this.frameMs = 20,
  })  : _encoder = encoderFactory(),
        frameSamples = (sampleRate * frameMs) ~/ 1000;

  final AudioCaptureSource capture;
  final AudioPlaybackSink playback;
  final int sampleRate;
  final int frameMs;
  final int frameSamples;
  final GroupMeshOpusDecoder Function() decoderFactory;
  final GroupMeshOpusEncoder _encoder;

  final _outboundCtrl = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get outbound => _outboundCtrl.stream;

  final _peers = <String, _PeerSlot>{};
  StreamSubscription<Int16List>? _captureSub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    await capture.start();
    await playback.start();
    _captureSub = capture.frames.listen(_onCaptureFrame);
    _started = true;
  }

  Future<void> stop() async {
    if (!_started) return;
    await _captureSub?.cancel();
    _captureSub = null;
    await capture.stop();
    await playback.stop();
    for (final slot in _peers.values) {
      slot.decoder.dispose();
    }
    _peers.clear();
    _started = false;
  }

  void addPeer(String peerKey) {
    _peers.putIfAbsent(peerKey, () => _PeerSlot(decoder: decoderFactory()));
  }

  void removePeer(String peerKey) {
    final slot = _peers.remove(peerKey);
    slot?.decoder.dispose();
  }

  void inbound(String peerKey, {required int seq, required Uint8List payload}) {
    final slot = _peers[peerKey];
    if (slot == null) return;
    if (seq <= slot.lastSeqAccepted) return;
    slot.lastSeqAccepted = seq;
    try {
      final pcm = slot.decoder.decode(payload);
      slot.jitter.add(pcm);
      // Cap buffer at `maxBuffered` frames (~60 ms). When network briefly
      // bursts, we keep the freshest data and drop the oldest so latency
      // doesn't grow unbounded.
      while (slot.jitter.length > _PeerSlot.maxBuffered) {
        slot.jitter.removeFirst();
      }
    } catch (_) {
      // Decode error: leave the jitter buffer alone — playback will mix
      // whatever's already queued for this peer.
    }
  }

  void _onCaptureFrame(Int16List pcm) {
    try {
      final encoded = _encoder.encode(pcm);
      _outboundCtrl.add(encoded);
    } catch (_) {
      // Encoder hiccup: skip this frame's outbound, but still mix inbound.
    }

    // Pop one frame from each peer's jitter buffer (or null = silence).
    final sources = <Int16List?>[
      for (final slot in _peers.values)
        slot.jitter.isEmpty ? null : slot.jitter.removeFirst(),
    ];
    final mixed = GroupMeshVoiceMixer.mix(sources, frameSamples);
    playback.push(mixed);
  }

  Future<void> dispose() async {
    await stop();
    _encoder.dispose();
    await _outboundCtrl.close();
  }
}
