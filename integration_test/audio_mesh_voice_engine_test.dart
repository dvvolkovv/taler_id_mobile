import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/core/audio/mesh_voice_audio_engine.dart';

class _FakeCapture implements AudioCaptureSource {
  final _ctrl = StreamController<Int16List>.broadcast();
  bool started = false;
  bool stopped = false;
  bool? micEnabled;
  @override
  Stream<Int16List> get frames => _ctrl.stream;
  @override
  Future<void> start() async { started = true; }
  @override
  Future<void> stop() async { stopped = true; }
  @override
  Future<void> setMicEnabled(bool e) async { micEnabled = e; }
  void emit(Int16List frame) => _ctrl.add(frame);
}

class _FakePlayback implements AudioPlaybackSink {
  final pushed = <Int16List>[];
  bool started = false;
  bool stopped = false;
  @override
  Future<void> start() async { started = true; }
  @override
  Future<void> stop() async { stopped = true; }
  @override
  Future<void> push(Int16List pcm) async { pushed.add(pcm); }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('engine encodes captured frames and emits via outbound stream', (_) async {
    final cap = _FakeCapture();
    final play = _FakePlayback();
    final engine = MeshVoiceAudioEngine(capture: cap, playback: play);
    final emitted = <Uint8List>[];
    final sub = engine.outbound.listen(emitted.add);

    await engine.start();
    expect(cap.started, isTrue);
    expect(play.started, isTrue);

    final frame = Int16List(320); // silence frame
    cap.emit(frame);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(emitted, isNotEmpty);
    expect(emitted.first.length, greaterThan(0));

    await engine.stop();
    expect(cap.stopped, isTrue);
    expect(play.stopped, isTrue);
    await sub.cancel();
  });

  testWidgets('engine decodes inbound and pushes PCM to playback', (_) async {
    final cap = _FakeCapture();
    final play = _FakePlayback();
    final engine = MeshVoiceAudioEngine(capture: cap, playback: play);
    await engine.start();

    // Encode silence to produce a valid Opus packet, then feed it back as inbound.
    final emittedFut = engine.outbound.first;
    cap.emit(Int16List(320));
    final opusPacket = await emittedFut;

    engine.inbound(seq: 1, payload: opusPacket);
    // Allow jitter buffer drain (drain timer fires every 20 ms).
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(play.pushed, isNotEmpty);
    expect(play.pushed.first.length, 320);

    await engine.stop();
  });
}
