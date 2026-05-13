import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/audio/group_mesh_voice_audio_engine.dart';
import 'package:taler_id_mobile/core/audio/mesh_voice_audio_engine.dart'
    show AudioCaptureSource, AudioPlaybackSink;

class _FakeCapture implements AudioCaptureSource {
  final _ctrl = StreamController<Int16List>.broadcast();
  @override
  Stream<Int16List> get frames => _ctrl.stream;
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setMicEnabled(bool enabled) async {}

  void emit(Int16List samples) => _ctrl.add(samples);
  Future<void> close() => _ctrl.close();
}

class _FakePlayback implements AudioPlaybackSink {
  final captured = <Int16List>[];
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> push(Int16List pcm) async {
    captured.add(pcm);
  }
}

class _FakeEncoder implements GroupMeshOpusEncoder {
  @override
  Uint8List encode(Int16List pcm) {
    // Marker byte + low-byte of each sample so tests can inspect output.
    final out = Uint8List(1 + pcm.length);
    out[0] = 0xEE;
    for (var i = 0; i < pcm.length; i++) {
      out[i + 1] = pcm[i] & 0xFF;
    }
    return out;
  }
  @override
  void dispose() {}
}

class _FakeDecoder implements GroupMeshOpusDecoder {
  @override
  Int16List decode(Uint8List payload) {
    // Skip leading marker byte; multiply each by 10 so non-zero data passes
    // through identifiably.
    return Int16List.fromList(
      [for (final b in payload.skip(1)) b * 10],
    );
  }
  @override
  void dispose() {}
}

void main() {
  test('engine fans out one encoded payload per capture frame', () async {
    final capture = _FakeCapture();
    final playback = _FakePlayback();
    final engine = GroupMeshVoiceAudioEngine(
      capture: capture,
      playback: playback,
      encoderFactory: () => _FakeEncoder(),
      decoderFactory: () => _FakeDecoder(),
    );

    await engine.start();
    final outbound = <Uint8List>[];
    final sub = engine.outbound.listen(outbound.add);

    capture.emit(Int16List.fromList([1, 2, 3]));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(outbound.length, 1);
    expect(outbound.first.first, 0xEE);

    await sub.cancel();
    await engine.stop();
    await capture.close();
  });

  test('addPeer + inbound routes to that peer; removePeer drops it cleanly',
      () async {
    final capture = _FakeCapture();
    final playback = _FakePlayback();
    final engine = GroupMeshVoiceAudioEngine(
      capture: capture,
      playback: playback,
      encoderFactory: () => _FakeEncoder(),
      decoderFactory: () => _FakeDecoder(),
    );
    await engine.start();
    engine.addPeer('peerA');

    engine.inbound('peerA', seq: 1, payload: Uint8List.fromList([0xEE, 5]));
    capture.emit(Int16List.fromList(List.filled(320, 0)));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(playback.captured.isNotEmpty, isTrue,
        reason: 'playback should have received at least one mixed frame');
    // Mixed output should contain peerA's contribution (5 * 10 = 50) in its
    // first sample with our test encoder/decoder pair.
    expect(playback.captured.first[0], 50);

    engine.removePeer('peerA');
    expect(
      () => engine.inbound('peerA', seq: 2, payload: Uint8List.fromList([0xEE, 6])),
      returnsNormally,
      reason: 'inbound for removed peer is a no-op, not an error',
    );

    await engine.stop();
    await capture.close();
  });

  test('inbound with stale seq is ignored', () async {
    final capture = _FakeCapture();
    final playback = _FakePlayback();
    final engine = GroupMeshVoiceAudioEngine(
      capture: capture,
      playback: playback,
      encoderFactory: () => _FakeEncoder(),
      decoderFactory: () => _FakeDecoder(),
    );
    await engine.start();
    engine.addPeer('peerA');

    engine.inbound('peerA', seq: 5, payload: Uint8List.fromList([0xEE, 9]));
    engine.inbound('peerA', seq: 4, payload: Uint8List.fromList([0xEE, 99]));
    capture.emit(Int16List.fromList(List.filled(320, 0)));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(playback.captured.first[0], 90,
        reason: 'stale seq=4 must be ignored; mix sees seq=5 → 9*10 = 90');

    await engine.stop();
    await capture.close();
  });
}
