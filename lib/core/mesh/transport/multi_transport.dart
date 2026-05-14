import 'dart:async';

import 'package:async/async.dart' show StreamGroup;
import 'package:flutter/foundation.dart';

import 'mesh_transport.dart';
import 'peer_id.dart';
import 'transport_preference.dart';

/// Composes multiple [MeshTransport]s into a single unified transport.
///
/// Dedup policy for discovery: first transport to surface a peer wins the
/// event; subsequent surfaces on other transports update internal routing
/// state but do NOT re-emit.
///
/// Routing policy for [send]: per-peer, use [TransportPreference] to pick
/// the best transport that currently knows the peer. Fall back to lower
/// preference on error.
class MultiTransport implements MeshTransport {
  final Map<TransportId, MeshTransport> _children;
  final TransportPreference _preference;

  final _discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossesCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();

  // Which transports currently know a given peer.
  final Map<PeerId, Set<TransportId>> _knownBy = {};

  final List<StreamSubscription<dynamic>> _subs = [];

  MultiTransport({
    required Map<TransportId, MeshTransport> children,
    TransportPreference? preference,
  })  : _children = children,
        _preference = preference ?? TransportPreference() {
    _wire();
  }

  void _wire() {
    for (final entry in _children.entries) {
      final id = entry.key;
      final t = entry.value;
      _subs.add(t.discoveries.listen((d) => _onDiscover(id, d)));
      _subs.add(t.losses.listen((l) => _onLoss(id, l)));
      _subs.add(t.inbound.listen((frame) {
        // Phase 3d hotfix: receiving traffic from a peer means the transport
        // CAN reach it (the connection / UDP socket is alive). Mark the peer
        // as known on this transport so subsequent send() / sendDatagram()
        // calls don't fail with "No transport knows" — Bonjour discovery is
        // asymmetric (Bonsoir on iOS sometimes resolves only one side of an
        // iPhone↔iPhone or iPhone↔Android pair) and without learning from
        // inbound traffic, the call_accept envelope can't reach the caller.
        _learnFromInbound(id, frame.srcPeer);
        _inboundCtrl.add(frame);
      }));
      _subs.add(t.inboundDatagrams.listen((dg) {
        _learnFromInbound(id, dg.srcPeer);
      }));
    }
  }

  void _learnFromInbound(TransportId id, PeerId peer) {
    final set = _knownBy.putIfAbsent(peer, () => <TransportId>{});
    if (set.add(id)) {
      // Synthetic discovery so `eligibility watcher` and other consumers
      // see the peer as online. We don't have host/port here — those came
      // (or didn't come) from the actual discovery layer; consumers that
      // need them must use the original Bonjour event. The 📡 dot only
      // needs presence.
      _discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: '', port: 0));
    }
  }

  void _onDiscover(TransportId id, PeerDiscovered d) {
    final set = _knownBy.putIfAbsent(d.peerId, () => <TransportId>{});
    final isFirst = set.isEmpty;
    set.add(id);
    if (isFirst) {
      _discoveriesCtrl.add(d);
    }
  }

  void _onLoss(TransportId id, PeerLost l) {
    final set = _knownBy[l.peerId];
    if (set == null) return;
    set.remove(id);
    if (set.isEmpty) {
      _knownBy.remove(l.peerId);
      _lossesCtrl.add(l);
    }
  }

  @override
  Stream<PeerDiscovered> get discoveries => _discoveriesCtrl.stream;
  @override
  Stream<PeerLost> get losses => _lossesCtrl.stream;
  @override
  Stream<InboundFrame> get inbound => _inboundCtrl.stream;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    for (final t in _children.values) {
      try {
        await t.startAdvertising(self);
      } catch (e) {
        debugPrint('[multi] child startAdvertising failed: $e');
      }
    }
  }

  @override
  Future<void> stopAdvertising() async {
    for (final t in _children.values) {
      try {
        await t.stopAdvertising();
      } catch (_) {}
    }
  }

  @override
  Future<void> connectTo(PeerId peer) async {
    final set = _knownBy[peer] ?? const <TransportId>{};
    if (set.isEmpty) {
      throw StateError('No transport knows $peer');
    }
    final ordered = _preference.orderedAmong(set);
    for (final id in ordered) {
      try {
        await _children[id]!.connectTo(peer);
        return;
      } catch (e) {
        debugPrint('[multi] connectTo $id failed: $e');
      }
    }
    throw StateError('All transports failed to connect to $peer');
  }

  @override
  Stream<InboundDatagram> get inboundDatagrams =>
      StreamGroup.merge(_children.values.map((c) => c.inboundDatagrams));

  /// Datagram preference order — same as the existing reliable-send order.
  /// Bonjour preferred over BLE: higher bandwidth, lower latency.
  static const List<TransportId> _datagramPreference = [
    TransportId.bonjour,
    TransportId.ble,
  ];

  @override
  void registerKnownPeer(PeerId peer) {
    for (final child in _children.values) {
      child.registerKnownPeer(peer);
    }
  }

  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    final knownOn = _knownBy[peer];
    if (knownOn == null || knownOn.isEmpty) {
      throw TransportUnavailable('MultiTransport: peer ${peer.toHex().substring(0, 12)} not on any child');
    }
    for (final id in _datagramPreference) {
      if (!knownOn.contains(id)) continue;
      final child = _children[id];
      if (child == null) continue;
      try {
        await child.sendDatagram(peer, data);
        return;
      } on TransportUnavailable {
        // Try the next transport in preference order.
        continue;
      }
    }
    throw TransportUnavailable(
        'MultiTransport: no datagram-capable transport for peer ${peer.toHex().substring(0, 12)} among ${knownOn.toList()}');
  }

  @override
  PeerStatus peerStatus(PeerId peer) {
    final knownOn = _knownBy[peer];
    if (knownOn == null || knownOn.isEmpty) return PeerStatus.offline;
    // Online if any child reports online for this peer.
    for (final id in knownOn) {
      final child = _children[id];
      if (child != null && child.peerStatus(peer) == PeerStatus.online) {
        return PeerStatus.online;
      }
    }
    return PeerStatus.offline;
  }

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    final set = _knownBy[peer] ?? const <TransportId>{};
    if (set.isEmpty) {
      throw StateError('No transport knows $peer');
    }
    final ordered = _preference.orderedAmong(set);
    Object? lastError;
    for (final id in ordered) {
      try {
        await _children[id]!.send(peer, data);
        return;
      } catch (e) {
        debugPrint('[multi] send via $id failed: $e — trying next');
        lastError = e;
      }
    }
    throw StateError('All transports failed to send to $peer: $lastError');
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    for (final t in _children.values) {
      await t.dispose();
    }
    await _discoveriesCtrl.close();
    await _lossesCtrl.close();
    await _inboundCtrl.close();
  }
}
