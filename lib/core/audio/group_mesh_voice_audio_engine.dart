import 'dart:async';
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
  Int16List? latestPcm;
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

  // Capture rebuffer: iOS's VoiceProcessingIO ignores setPreferredIOBufferDuration
  // on some devices (notably iPhone 17 / iOS 26 — observed in 3-way mesh-gc
  // hardware smoke 2026-05-14). It delivers 10ms (160-sample) PCM chunks at
  // 100Hz instead of the requested 20ms at 50Hz, so the encoder emits twice as
  // many Opus packets and the receiver's playback queue grows 2x faster than
  // it drains — manifesting as audible lag + cumulative drift. Buffering
  // captures into stable `frameSamples`-sized chunks here keeps the wire rate
  // and playback cadence at 50Hz regardless of the OS's chunking decision.
  late final Int16List _captureBuffer = Int16List(frameSamples);
  int _captureBufferFill = 0;

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
      slot.latestPcm = slot.decoder.decode(payload);
    } catch (_) {
      // Decode errors keep the prior latestPcm; next tick mixes silence for
      // this peer if no new frame arrives.
      slot.latestPcm = null;
    }
  }

  void _onCaptureFrame(Int16List pcm) {
    // Re-chunk the incoming PCM into stable `frameSamples`-sized slices.
    // Native capture may deliver any size (10ms, 20ms, or larger), so loop
    // until we've consumed the whole input — emitting one Opus + playback
    // tick per filled buffer.
    var offset = 0;
    while (offset < pcm.length) {
      final remaining = frameSamples - _captureBufferFill;
      final available = pcm.length - offset;
      final take = available < remaining ? available : remaining;
      _captureBuffer.setRange(
          _captureBufferFill, _captureBufferFill + take, pcm, offset);
      _captureBufferFill += take;
      offset += take;
      if (_captureBufferFill < frameSamples) break;
      _emitFrame();
      _captureBufferFill = 0;
    }
  }

  void _emitFrame() {
    try {
      final encoded = _encoder.encode(_captureBuffer);
      _outboundCtrl.add(encoded);
    } catch (_) {
      // Encoder hiccup: skip this frame's outbound, but still mix inbound.
    }

    final sources = <Int16List?>[
      for (final slot in _peers.values) slot.latestPcm,
    ];
    for (final slot in _peers.values) {
      slot.latestPcm = null;
    }
    final mixed = GroupMeshVoiceMixer.mix(sources, frameSamples);
    playback.push(mixed);
  }

  Future<void> dispose() async {
    await stop();
    _encoder.dispose();
    await _outboundCtrl.close();
  }
}
