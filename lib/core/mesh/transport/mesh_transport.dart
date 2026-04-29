import 'dart:async';
import 'dart:typed_data';

import 'frame.dart';
import 'peer_id.dart';
import 'transport_preference.dart';

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

/// Event emitted when a datagram (unreliable, low-latency) arrives from a peer.
/// Used for voice / file streaming. Decryption + replay-window check is the
/// caller's responsibility (see `MeshDatagramCipher`).
class InboundDatagram {
  final PeerId srcPeer;
  final Uint8List bytes;
  final TransportId via;
  InboundDatagram({required this.srcPeer, required this.bytes, required this.via});
}

/// Information about this device for advertising.
class DeviceInfo {
  final PeerId devicePk;
  final String serviceName;
  DeviceInfo({required this.devicePk, required this.serviceName});
}

/// Reachability state for a given peer at the moment of the query.
/// `online` = visible in active discovery on at least one transport.
/// `offline` = not currently discovered (used to be, or never was).
/// `unknown` = transport has no state for this peer (e.g., never advertised
/// here). Currently we collapse `offline` and `unknown` for callers; the
/// distinction is reserved for future BLE-only peer tracking.
enum PeerStatus { online, offline, unknown }

/// Transport layer — provides authenticated byte channel between peers.
abstract class MeshTransport {
  Stream<PeerDiscovered> get discoveries;
  Stream<PeerLost> get losses;
  Stream<InboundFrame> get inbound;

  Future<void> startAdvertising(DeviceInfo self);
  Future<void> stopAdvertising();
  Future<void> connectTo(PeerId peer);
  Future<void> send(PeerId peer, Uint8List data);

  /// Datagram channel — unreliable, low-latency. Used for voice frames.
  /// Frames are NOT encrypted at this layer; callers should wrap payloads
  /// with `MeshDatagramCipher`. Throws [TransportUnavailable] if no
  /// datagram path to [peer] exists right now.
  Stream<InboundDatagram> get inboundDatagrams;
  Future<void> sendDatagram(PeerId peer, Uint8List data);

  /// Synchronous reachability query. Used by UI eligibility checks (e.g.,
  /// "show mesh-call button only if the peer is reachable").
  PeerStatus peerStatus(PeerId peer);

  Future<void> dispose();
}

/// Thrown by `sendDatagram` when the requested peer has no reachable
/// datagram path on any active transport (e.g., peer is BLE-only and the
/// datagram-supporting transports haven't discovered them).
class TransportUnavailable implements Exception {
  final String message;
  TransportUnavailable(this.message);
  @override
  String toString() => 'TransportUnavailable: $message';
}
