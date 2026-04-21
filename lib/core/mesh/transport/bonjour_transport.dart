import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bonsoir/bonsoir.dart';

import 'frame.dart';
import 'mesh_transport.dart';
import 'peer_id.dart';

class _ConnectedPeer {
  final Socket socket;
  final PeerId peerId;
  _ConnectedPeer({required this.socket, required this.peerId});
}

class _PeerAddress {
  final String host;
  final int port;
  _PeerAddress({required this.host, required this.port});
}

class BonjourTransport implements MeshTransport {
  static const String serviceType = '_talermesh._tcp';

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  ServerSocket? _server;
  PeerId? _selfPk;

  final Map<PeerId, _ConnectedPeer> _connections = {};
  final Map<String, PeerId> _nameToPeerId = {};
  final Map<PeerId, _PeerAddress> _peerAddresses = {};

  final _discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossesCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();

  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;

  @override
  Stream<PeerDiscovered> get discoveries => _discoveriesCtrl.stream;
  @override
  Stream<PeerLost> get losses => _lossesCtrl.stream;
  @override
  Stream<InboundFrame> get inbound => _inboundCtrl.stream;

  /// The TCP port this transport is listening on.
  /// Returns 0 if [startAdvertising] has not been called yet.
  int get listenPort => _server?.port ?? 0;

  /// Manually inject a peer's address, bypassing mDNS discovery.
  ///
  /// This is useful for integration tests running on environments where
  /// mDNS multicast is unreliable (e.g., Android emulators), or for
  /// scenarios where the address is known through an out-of-band channel.
  void seedPeer({
    required PeerId peerId,
    required String host,
    required int port,
  }) {
    _peerAddresses[peerId] = _PeerAddress(host: host, port: port);
    _discoveriesCtrl.add(PeerDiscovered(
      peerId: peerId,
      host: host,
      port: port,
    ));
  }

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    _selfPk = self.devicePk;
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_handleIncomingSocket);

    final service = BonsoirService(
      name: self.serviceName,
      type: serviceType,
      port: _server!.port,
      attributes: {
        'pk': self.devicePk.toHex(),
        'ver': '1',
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();

    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.ready;
    await _discovery!.start();
    final stream = _discovery!.eventStream;
    if (stream != null) {
      _discoverySub = stream.listen(_onBonjourEvent);
    }
  }

  void _onBonjourEvent(BonsoirDiscoveryEvent event) {
    final service = event.service;
    if (service == null) return;
    final pkHex = service.attributes['pk'];
    if (pkHex == null) return;
    final PeerId peerId;
    try {
      peerId = PeerId.fromHex(pkHex);
    } catch (_) {
      return;
    }
    switch (event.type) {
      case BonsoirDiscoveryEventType.discoveryServiceResolved:
        if (_selfPk != null && peerId == _selfPk) {
          return; // don't announce self as a peer
        }
        if (service is ResolvedBonsoirService) {
          _nameToPeerId[service.name] = peerId;
          _peerAddresses[peerId] = _PeerAddress(
            host: service.host ?? '',
            port: service.port,
          );
          _discoveriesCtrl.add(PeerDiscovered(
            peerId: peerId,
            host: service.host ?? '',
            port: service.port,
            attributes: Map<String, String>.from(service.attributes),
          ));
        }
        break;
      case BonsoirDiscoveryEventType.discoveryServiceLost:
        if (_selfPk != null && peerId == _selfPk) {
          return; // skip self
        }
        final lostPeer = _nameToPeerId.remove(service.name);
        if (lostPeer != null) {
          _peerAddresses.remove(lostPeer);
          _lossesCtrl.add(PeerLost(lostPeer));
        }
        break;
      default:
        break;
    }
  }

  void _handleIncomingSocket(Socket socket) {
    final buffer = BytesBuilder();
    socket.listen(
      (chunk) {
        buffer.add(chunk);
        _tryDispatchFrames(buffer, socket);
      },
      onDone: () {
        PeerId? found;
        _connections.forEach((k, v) {
          if (identical(v.socket, socket)) found = k;
        });
        if (found != null) _connections.remove(found);
        socket.destroy();
      },
      onError: (_) => socket.destroy(),
    );
  }

  void _tryDispatchFrames(BytesBuilder buffer, Socket socket) {
    while (true) {
      final all = buffer.toBytes();
      if (all.length < Frame.headerSize) return;
      final length = (all[2] << 8) | all[3];
      final total = Frame.headerSize + length;
      if (all.length < total) return;
      final frameBytes = Uint8List.fromList(all.sublist(0, total));
      final rest = Uint8List.fromList(all.sublist(total));
      buffer.clear();
      buffer.add(rest);
      try {
        final frame = Frame.decode(frameBytes);
        _connections[frame.srcPk] =
            _ConnectedPeer(socket: socket, peerId: frame.srcPk);
        _inboundCtrl.add(InboundFrame(
          srcPeer: frame.srcPk,
          type: frame.type,
          bytes: frame.payload,
        ));
      } on FormatException {
        socket.destroy();
        return;
      }
    }
  }

  @override
  Future<void> connectTo(PeerId peer) async {
    if (_connections.containsKey(peer)) return;
    final addr = _peerAddresses[peer];
    if (addr == null) {
      throw StateError('Unknown peer $peer — not discovered yet');
    }
    final socket = await Socket.connect(addr.host, addr.port);
    _connections[peer] = _ConnectedPeer(socket: socket, peerId: peer);
    final buffer = BytesBuilder();
    socket.listen(
      (chunk) {
        buffer.add(chunk);
        _tryDispatchFrames(buffer, socket);
      },
      onDone: () {
        _connections.remove(peer);
        socket.destroy();
      },
      onError: (_) => socket.destroy(),
    );
  }

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    var conn = _connections[peer];
    if (conn == null) {
      await connectTo(peer);
      conn = _connections[peer]!;
    }
    conn.socket.add(data);
    await conn.socket.flush();
  }

  @override
  Future<void> stopAdvertising() async {
    await _broadcast?.stop();
    _broadcast = null;
    await _discovery?.stop();
    await _discoverySub?.cancel();
    _discoverySub = null;
    _discovery = null;
    await _server?.close();
    _server = null;
  }

  @override
  Future<void> dispose() async {
    await stopAdvertising();
    // Copy values before iterating to avoid ConcurrentModificationError:
    // socket.destroy() triggers onDone which removes the entry from _connections.
    final conns = _connections.values.toList();
    for (final conn in conns) {
      conn.socket.destroy();
    }
    _connections.clear();
    await _discoveriesCtrl.close();
    await _lossesCtrl.close();
    await _inboundCtrl.close();
  }
}
