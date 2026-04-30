import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;

import 'frame.dart';
import 'mesh_discovery_supervisor.dart';
import 'mesh_transport.dart';
import 'peer_id.dart';
import 'transport_preference.dart';

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

  BonjourTransport();
  BonjourTransport._();

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  ServerSocket? _server;
  PeerId? _selfPk;

  RawDatagramSocket? _udpSocket;
  final Map<PeerId, ({String host, int port})> _peerUdpEndpoints = {};
  final _datagramCtrl = StreamController<InboundDatagram>.broadcast();

  final Map<PeerId, _ConnectedPeer> _connections = {};
  final Map<String, PeerId> _nameToPeerId = {};
  final Map<PeerId, _PeerAddress> _peerAddresses = {};

  final _discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossesCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();

  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;

  MeshDiscoverySupervisor? _supervisor;
  _LifecycleAdapter? _lifecycleAdapter;
  StreamController<AppLifecycleState>? _lifecycleCtrl;

  @override
  Stream<PeerDiscovered> get discoveries => _discoveriesCtrl.stream;
  @override
  Stream<PeerLost> get losses => _lossesCtrl.stream;
  @override
  Stream<InboundFrame> get inbound => _inboundCtrl.stream;

  /// The TCP port this transport is listening on.
  /// Returns 0 if [startAdvertising] has not been called yet.
  int get listenPort => _server?.port ?? 0;

  /// Mesh Debug — total Bonsoir discovery reinits the supervisor has
  /// fired since this transport was started. Returns 0 when the
  /// supervisor is not yet attached (e.g., transport stopped).
  int get discoveryReinitCount => _supervisor?.reinitCount ?? 0;

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
    debugPrint('[mesh-bonjour] startAdvertising name=${self.serviceName} pk=${self.devicePk.toHex().substring(0, 12)}...');
    _selfPk = self.devicePk;
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_handleIncomingSocket);
    debugPrint('[mesh-bonjour] TCP server listening on port ${_server!.port}');

    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    debugPrint('[mesh-bonjour] UDP socket listening on port ${_udpSocket!.port}');
    // ignore: avoid_print
    print('[mesh-bonjour/diag] my UDP socket bound to ${_udpSocket!.address.address}:${_udpSocket!.port}');
    _udpSocket!.listen(_handleDatagramEvent);

    final service = BonsoirService(
      name: self.serviceName,
      type: serviceType,
      port: _server!.port,
      attributes: {
        'pk': self.devicePk.toHex(),
        'ver': '1',
        'udp_port': _udpSocket!.port.toString(),
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
    debugPrint('[mesh-bonjour] broadcast started');

    _lifecycleCtrl = StreamController<AppLifecycleState>.broadcast();
    _lifecycleAdapter = _LifecycleAdapter((state) {
      _lifecycleCtrl?.add(state);
    });
    WidgetsBinding.instance.addObserver(_lifecycleAdapter!);

    _supervisor = MeshDiscoverySupervisor(
      reinit: (reason) async {
        debugPrint('[mesh-bonjour] supervisor reinit reason=$reason');
        await _restartDiscovery();
      },
      connectivityStream: Connectivity().onConnectivityChanged,
      lifecycleStream: _lifecycleCtrl!.stream,
    );

    await _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    await _discoverySub?.cancel();
    _discoverySub = null;
    await _discovery?.stop();

    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.ready;
    await _discovery!.start();
    debugPrint('[mesh-bonjour] discovery started, type=$serviceType');
    final stream = _discovery!.eventStream;
    if (stream == null) {
      debugPrint('[mesh-bonjour] WARNING: discovery.eventStream is null — discovery WILL NOT WORK');
      return;
    }
    debugPrint('[mesh-bonjour] subscribing to discovery eventStream');
    _discoverySub = stream.listen(
      _onBonjourEvent,
      onError: (Object e) {
        debugPrint('[mesh-bonjour] discovery stream error: $e');
      },
      onDone: () {
        debugPrint('[mesh-bonjour] discovery stream CLOSED');
      },
    );
    _supervisor?.onDiscoveryStarted();
  }

  Future<void> _restartDiscovery() async {
    await _startDiscovery();
  }

  void _onBonjourEvent(BonsoirDiscoveryEvent event) {
    final service = event.service;
    debugPrint('[mesh-bonjour] event: ${event.type} service=${service?.name ?? "null"}');
    if (service == null) return;

    // Bonsoir 5.x does not auto-resolve: after discoveryServiceFound we must
    // explicitly call resolveService() so the resolved event is emitted with
    // the service host/port. Without this, discoveryServiceResolved never
    // fires and the peer stays invisible.
    if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
      debugPrint('[mesh-bonjour] resolving service ${service.name}');
      // Fire-and-forget resolve — bonsoir may fire a second found for a
      // peer that has already moved out of its internal cache, which makes
      // resolveService throw. Swallow those here; the next found → resolve
      // cycle will recover.
      _discovery?.serviceResolver.resolveService(service).catchError((e) {
        debugPrint('[mesh-bonjour] resolveService(${service.name}) failed: $e');
      });
      return;
    }

    final pkHex = service.attributes['pk'];
    if (pkHex == null) {
      debugPrint('[mesh-bonjour] event for ${service.name} missing pk attribute, skipping');
      return;
    }
    final PeerId peerId;
    try {
      peerId = PeerId.fromHex(pkHex);
    } catch (_) {
      return;
    }
    switch (event.type) {
      case BonsoirDiscoveryEventType.discoveryServiceResolved:
        if (_selfPk != null && peerId == _selfPk) {
          debugPrint('[mesh-bonjour] resolved SELF (${service.name}), skipping');
          return; // don't announce self as a peer
        }
        // Phase 2.1 — only count non-self resolves as proof discovery is
        // healthy. Seeing your own service is not enough on iOS, where the
        // resolver can echo self while still failing to find others.
        _supervisor?.onDiscoveryEvent();
        if (service is ResolvedBonsoirService) {
          debugPrint('[mesh-bonjour] resolved peer ${service.name} at ${service.host}:${service.port} pk=${peerId.toHex().substring(0, 12)}...');
          _nameToPeerId[service.name] = peerId;
          _peerAddresses[peerId] = _PeerAddress(
            host: service.host ?? '',
            port: service.port,
          );
          final udpPortStr = service.attributes['udp_port'];
          final udpPort = udpPortStr != null ? int.tryParse(udpPortStr) : null;
          if (udpPort != null && service.host != null) {
            _peerUdpEndpoints[peerId] = (host: service.host!, port: udpPort);
            // ignore: avoid_print
            print('[mesh-bonjour/diag] resolved udp_port: peer=${peerId.toHex().substring(0, 12)} ${service.host}:$udpPort');
          } else {
            // ignore: avoid_print
            print('[mesh-bonjour/diag] resolved WITHOUT udp_port: peer=${peerId.toHex().substring(0, 12)} attrs=${service.attributes}');
          }
          _discoveriesCtrl.add(PeerDiscovered(
            peerId: peerId,
            host: service.host ?? '',
            port: service.port,
            attributes: Map<String, String>.from(service.attributes),
          ));
        } else {
          debugPrint('[mesh-bonjour] resolved event but service is not ResolvedBonsoirService: ${service.runtimeType}');
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
  Stream<InboundDatagram> get inboundDatagrams => _datagramCtrl.stream;

  @override
  PeerStatus peerStatus(PeerId peer) {
    return _peerUdpEndpoints.containsKey(peer)
        ? PeerStatus.online
        : PeerStatus.offline;
  }

  int _bonjourTxCounter = 0;
  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    final endpoint = _peerUdpEndpoints[peer];
    final socket = _udpSocket;
    if (endpoint == null || socket == null) {
      // ignore: avoid_print
      print('[mesh-bonjour/diag] sendDatagram: NO ENDPOINT peer=${peer.toHex().substring(0, 12)} endpoint=$endpoint socket=${socket != null} known_peers=${_peerUdpEndpoints.keys.map((k) => k.toHex().substring(0, 12)).toList()}');
      throw TransportUnavailable('Bonjour: no UDP endpoint for peer ${peer.toHex().substring(0, 12)}');
    }
    if (data.length > 1200) {
      throw ArgumentError('datagram too large: ${data.length} bytes (max 1200 to avoid IPv4 fragmentation)');
    }
    final sent = socket.send(data, InternetAddress(endpoint.host), endpoint.port);
    _bonjourTxCounter++;
    if (_bonjourTxCounter == 1 || _bonjourTxCounter % 50 == 0) {
      // ignore: avoid_print
      print('[mesh-bonjour/diag] sendDatagram: tx=$_bonjourTxCounter sent=$sent bytes peer=${peer.toHex().substring(0, 12)} → ${endpoint.host}:${endpoint.port}');
    }
  }

  int _bonjourRxCounter = 0;
  void _handleDatagramEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final socket = _udpSocket;
    if (socket == null) return;
    final dg = socket.receive();
    if (dg == null) return;

    PeerId? srcPeer;
    for (final entry in _peerUdpEndpoints.entries) {
      if (entry.value.host == dg.address.address && entry.value.port == dg.port) {
        srcPeer = entry.key;
        break;
      }
    }
    _bonjourRxCounter++;
    if (srcPeer == null) {
      // ignore: avoid_print
      print('[mesh-bonjour/diag] rx UNKNOWN SRC count=$_bonjourRxCounter from=${dg.address.address}:${dg.port} bytes=${dg.data.length} known_peers=${_peerUdpEndpoints.entries.map((e) => "${e.key.toHex().substring(0, 8)}@${e.value.host}:${e.value.port}").toList()}');
      return;
    }
    if (_bonjourRxCounter == 1 || _bonjourRxCounter % 50 == 0) {
      // ignore: avoid_print
      print('[mesh-bonjour/diag] rx OK count=$_bonjourRxCounter from=${srcPeer.toHex().substring(0, 12)} bytes=${dg.data.length}');
    }
    _datagramCtrl.add(InboundDatagram(
      srcPeer: srcPeer,
      bytes: Uint8List.fromList(dg.data),
      via: TransportId.bonjour,
    ));
  }

  @override
  Future<void> stopAdvertising() async {
    await _supervisor?.dispose();
    _supervisor = null;
    if (_lifecycleAdapter != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleAdapter!);
      _lifecycleAdapter = null;
    }
    await _lifecycleCtrl?.close();
    _lifecycleCtrl = null;
    await _broadcast?.stop();
    _broadcast = null;
    await _discovery?.stop();
    await _discoverySub?.cancel();
    _discoverySub = null;
    _discovery = null;
    await _server?.close();
    _server = null;
    _udpSocket?.close();
    _udpSocket = null;
    _peerUdpEndpoints.clear();
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
    await _datagramCtrl.close();
  }

  /// Test-only constructor: builds a `BonjourTransport` with a pre-bound
  /// UDP socket and skips Bonsoir advertise/discovery. Use only from
  /// `test/` files. Pairs with `testRegisterPeer`.
  @visibleForTesting
  factory BonjourTransport.testHarness({required RawDatagramSocket udpSocket}) {
    final t = BonjourTransport._();
    t._udpSocket = udpSocket;
    udpSocket.listen(t._handleDatagramEvent);
    return t;
  }

  /// Test-only: pre-populate the peer UDP endpoint cache. Use only from
  /// `test/` files. Production populates via `bonsoir`-resolved TXT.
  @visibleForTesting
  void testRegisterPeer(PeerId peer, String host, int port) {
    _peerUdpEndpoints[peer] = (host: host, port: port);
  }
}

class _LifecycleAdapter with WidgetsBindingObserver {
  final void Function(AppLifecycleState) onState;
  _LifecycleAdapter(this.onState);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onState(state);
  }
}
