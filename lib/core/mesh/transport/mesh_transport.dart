import 'dart:async';
import 'dart:typed_data';

import 'frame.dart';
import 'peer_id.dart';

/// Event emitted when a new peer is discovered on the network.
class PeerDiscovered {
  final PeerId peerId;
  final String host;
  final int port;
  final Map<String, String> attributes;

  PeerDiscovered({
    required this.peerId,
    required this.host,
    required this.port,
    this.attributes = const {},
  });
}

/// Event emitted when a previously-discovered peer is no longer reachable.
class PeerLost {
  final PeerId peerId;
  PeerLost(this.peerId);
}

/// Event emitted when a decoded frame arrives from a peer.
/// `type` preserves the Frame-level dispatch marker so upper layers can
/// route handshake vs. data frames without re-parsing.
class InboundFrame {
  final PeerId srcPeer;
  final FrameType type;
  final Uint8List bytes; // Frame payload (already stripped of transport header)
  InboundFrame({required this.srcPeer, required this.type, required this.bytes});
}

/// Information about this device for advertising.
class DeviceInfo {
  final PeerId devicePk;
  final String serviceName;
  DeviceInfo({required this.devicePk, required this.serviceName});
}

/// Transport layer — provides authenticated byte channel between peers.
abstract class MeshTransport {
  Stream<PeerDiscovered> get discoveries;
  Stream<PeerLost> get losses;
  Stream<InboundFrame> get inbound;

  Future<void> startAdvertising(DeviceInfo self);
  Future<void> stopAdvertising();
  Future<void> connectTo(PeerId peer);
  Future<void> send(PeerId peer, Uint8List data);
  Future<void> dispose();
}
