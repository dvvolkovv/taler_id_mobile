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
    // iOS quirk: RawDatagramSocket.send returns 0 (silent drop) for unicast
    // outbound on the local network unless broadcastEnabled is true. Setting
    // it to true is a no-op on Android and unblocks LAN UDP on iOS.
    try {
      _udpSocket!.broadcastEnabled = true;
    } catch (_) {}
    debugPrint('[mesh-bonjour] UDP socket listening on port ${_udpSocket!.port}');
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
            // iOS Bonsoir returns mDNS hostname (e.g. "Android_X.local.").
            // RawDatagramSocket.send takes InternetAddress which only accepts
            // numeric IPs — and our reverse-lookup compares to dg.address.address
            // which is also numeric. Resolve hostname → IP and cache the IP.
            debugPrint('[mesh-bonjour] caching UDP endpoint for ${peerId.toHex().substring(0, 12)}: ${service.host}:$udpPort');
            unawaited(_cacheUdpEndpoint(peerId, service.host!, udpPort));
          } else {
            debugPrint('[mesh-bonjour] peer ${peerId.toHex().substring(0, 12)} has no udp_port TXT (attrs=${service.attributes.keys.toList()}) — datagrams from this peer will be dropped as srcPeer=null');
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

  /// Resolve [host] (which may be an mDNS hostname like "X.local.") to a
  /// numeric IP and cache `(ip, udpPort)` in [_peerUdpEndpoints]. Required
  /// because `InternetAddress` does not accept hostnames (used in
  /// [sendDatagram] and reverse-lookup in [_handleDatagramEvent]).
  Future<void> _cacheUdpEndpoint(PeerId peerId, String host, int udpPort) async {
    String ip = host;
    bool isLiteral = false;
    try {
      InternetAddress(host); // throws if not a numeric IP
      isLiteral = true;
    } catch (_) {}
    if (!isLiteral) {
      try {
        final addrs = await InternetAddress.lookup(host);
        final ipv4 = addrs.firstWhere(
          (a) => a.type == InternetAddressType.IPv4,
          orElse: () => addrs.first,
        );
        ip = ipv4.address;
      } catch (e) {
        debugPrint('[mesh-bonjour] udp_port hostname lookup($host) failed: $e — peer ${peerId.toHex().substring(0, 12)} skipped');
        return;
      }
    }
    _peerUdpEndpoints[peerId] = (host: ip, port: udpPort);
  }

  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    final endpoint = _peerUdpEndpoints[peer];
    final socket = _udpSocket;
    if (endpoint == null || socket == null) {
      throw TransportUnavailable('Bonjour: no UDP endpoint for peer ${peer.toHex().substring(0, 12)}');
    }
    if (data.length > 1200) {
      throw ArgumentError('datagram too large: ${data.length} bytes (max 1200 to avoid IPv4 fragmentation)');
    }
    socket.send(data, InternetAddress(endpoint.host), endpoint.port);
  }

  void _handleDatagramEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final socket = _udpSocket;
    if (socket == null) return;
    final dg = socket.receive();
    if (dg == null) return;

    // Reverse-lookup: find which peer this came from by matching source
    // (host, port) against `_peerUdpEndpoints`. Slow O(N) but N = peer
    // count which is small (few-to-tens for 1-hop direct mesh).
    PeerId? srcPeer;
    for (final entry in _peerUdpEndpoints.entries) {
      if (entry.value.host == dg.address.address && entry.value.port == dg.port) {
        srcPeer = entry.key;
        break;
      }
    }
    if (srcPeer == null) {
      // Datagram from an unknown source — ignore. Could be a peer that
      // hasn't completed Bonjour discovery yet, or just stray UDP.
      _datagramSrcUnknownCount++;
      _maybeLogDatagramDrop(dg.address.address, dg.port);
      return;
    }
    _datagramCtrl.add(InboundDatagram(
      srcPeer: srcPeer,
      bytes: Uint8List.fromList(dg.data),
      via: TransportId.bonjour,
    ));
  }

  int _datagramSrcUnknownCount = 0;
  DateTime? _datagramSrcUnknownLast;

  void _maybeLogDatagramDrop(String host, int port) {
    final now = DateTime.now();
    if (_datagramSrcUnknownLast != null &&
        now.difference(_datagramSrcUnknownLast!) <= const Duration(seconds: 5)) {
      return;
    }
    _datagramSrcUnknownLast = now;
    debugPrint(
      '[mesh-bonjour] dropped $_datagramSrcUnknownCount datagrams in last 5s from unknown source (last $host:$port); '
      'known endpoints: ${_peerUdpEndpoints.entries.map((e) => "${e.key.toHex().substring(0, 12)}@${e.value.host}:${e.value.port}").join(", ")}',
    );
    _datagramSrcUnknownCount = 0;
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
