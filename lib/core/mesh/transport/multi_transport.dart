import 'dart:async';
import 'dart:typed_data';

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
      _subs.add(t.inbound.listen(_inboundCtrl.add));
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
