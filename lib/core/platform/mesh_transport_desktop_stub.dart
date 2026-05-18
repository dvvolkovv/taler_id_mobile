import 'dart:async';
import 'dart:typed_data';

import '../mesh/transport/frame.dart';
import '../mesh/transport/mesh_transport.dart';
import '../mesh/transport/peer_id.dart';

/// Desktop stub for [MeshTransport].
///
/// On desktop platforms (macOS / Windows / Linux) mesh networking is not
/// supported. This stub implements the full [MeshTransport] interface with
/// no-op methods and empty streams so that the rest of the codebase compiles
/// and runs without crashing — while mesh discovery / messaging never
/// actually starts.
///
/// Registered via GetIt in [setupDependencies] when
/// [PlatformUtils.instance.isMobile] is false.
class MeshTransportDesktopStub implements MeshTransport {
  const MeshTransportDesktopStub();

  @override
  Stream<PeerDiscovered> get discoveries => const Stream.empty();

  @override
  Stream<PeerLost> get losses => const Stream.empty();

  @override
  Stream<InboundFrame> get inbound => const Stream.empty();

  @override
  Stream<InboundDatagram> get inboundDatagrams => const Stream.empty();

  @override
  Future<void> startAdvertising(DeviceInfo self) async {}

  @override
  Future<void> stopAdvertising() async {}

  @override
  Future<void> connectTo(PeerId peer) async {}

  @override
  Future<void> send(PeerId peer, Uint8List data) async {}

  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {}

  @override
  void registerKnownPeer(PeerId peer) {}

  @override
  PeerStatus peerStatus(PeerId peer) => PeerStatus.unknown;

  @override
  Future<void> dispose() async {}
}
