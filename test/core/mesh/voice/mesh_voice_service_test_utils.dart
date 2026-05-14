import 'dart:async';
import 'dart:typed_data';

import 'package:taler_id_mobile/core/audio/mesh_voice_audio_engine.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_service.dart';

class FakeMessagingService implements MeshMessagingService {
  final _inboundCtrl = StreamController<InboundEnvelope>.broadcast();
  final sentEnvelopes = <({PeerId toUserPk, Envelope envelope})>[];

  @override
  Stream<InboundEnvelope> get inbound => _inboundCtrl.stream;

  @override
  Future<void> sendEnvelope({required PeerId toUserPk, required Envelope envelope}) async {
    sentEnvelopes.add((toUserPk: toUserPk, envelope: envelope));
  }

  void emitInbound(InboundEnvelope m) => _inboundCtrl.add(m);

  // Other MeshMessagingService members — throw if hit by accident.
  @override
  noSuchMethod(Invocation i) =>
      throw UnimplementedError('FakeMessagingService.${i.memberName}');
}

class FakeTransport implements MeshTransport {
  final _discCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();
  final _datagramCtrl = StreamController<InboundDatagram>.broadcast();
  final sentDatagrams = <(PeerId, Uint8List)>[];

  @override Stream<PeerDiscovered> get discoveries => _discCtrl.stream;
  @override Stream<PeerLost> get losses => _lossCtrl.stream;
  @override Stream<InboundFrame> get inbound => _inboundCtrl.stream;
  @override Stream<InboundDatagram> get inboundDatagrams => _datagramCtrl.stream;

  @override Future<void> startAdvertising(DeviceInfo self) async {}
  @override Future<void> stopAdvertising() async {}
  @override Future<void> connectTo(PeerId peer) async {}
  @override Future<void> send(PeerId peer, Uint8List data) async {}
  @override Future<void> dispose() async {}

  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    sentDatagrams.add((peer, data));
  }

  final registeredPeers = <PeerId>[];
  @override
  void registerKnownPeer(PeerId peer) {
    registeredPeers.add(peer);
  }

  @override
  PeerStatus peerStatus(PeerId peer) => PeerStatus.online;

  void emitDatagram(InboundDatagram dg) => _datagramCtrl.add(dg);
}

class FakeAudioEngine implements MeshVoiceAudioEngine {
  bool started = false;
  bool stopped = false;
  final _outboundCtrl = StreamController<Uint8List>.broadcast();
  final inboundFrames = <(int seq, Uint8List payload)>[];

  /// If non-null, [start] awaits this future before completing.
  /// Tests use this to simulate slow audio init and trigger races.
  Completer<void>? startBlocker;

  @override Stream<Uint8List> get outbound => _outboundCtrl.stream;

  @override Future<void> start() async {
    if (startBlocker != null) await startBlocker!.future;
    started = true;
  }
  @override Future<void> stop() async { stopped = true; }
  @override
  void inbound({required int seq, required Uint8List payload}) {
    inboundFrames.add((seq, payload));
  }

  void emitOutbound(Uint8List bytes) => _outboundCtrl.add(bytes);

  @override noSuchMethod(Invocation i) =>
      throw UnimplementedError('FakeAudioEngine.${i.memberName}');
}

class MeshVoiceTestHarness {
  final FakeMessagingService fakeMessaging;
  final FakeTransport fakeTransport;
  final FakeAudioEngine fakeAudioEngine;
  final MeshVoiceService svc;

  MeshVoiceTestHarness._(this.fakeMessaging, this.fakeTransport,
      this.fakeAudioEngine, this.svc);

  static MeshVoiceTestHarness build() {
    final messaging = FakeMessagingService();
    final transport = FakeTransport();
    final audio = FakeAudioEngine();
    final svc = MeshVoiceService(
      messaging: messaging,
      transport: transport,
      audioEngineFactory: () => audio,
    );
    return MeshVoiceTestHarness._(messaging, transport, audio, svc);
  }
}
