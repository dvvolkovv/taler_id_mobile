import 'dart:async';

import '../mesh/transport/mesh_transport.dart';
import '../mesh/transport/peer_id.dart';

/// Minimal interface needed by the watcher. HiveContactKeyStore implements it.
/// Defining as an abstract here lets unit tests inject a fake without pulling
/// the full Hive store + path_provider dependency.
abstract class ContactKeyStoreLookup {
  PeerId? lookupUserByDevice(PeerId devicePk);
  Iterable<(String, PeerId)> allUserIdMappings();
}

/// Tracks per-userId online state derived from MeshTransport discovery events
/// + ContactKeyStore mappings. A userId is "online" iff at least one of its
/// known devicePks has been discovered (and not yet lost).
class MeshPeerEligibilityWatcher {
  final MeshTransport transport;
  final ContactKeyStoreLookup contactKeyStore;

  StreamSubscription<PeerDiscovered>? _discSub;
  StreamSubscription<PeerLost>? _lossSub;
  final Map<String, Set<PeerId>> _onlineDevices = {};
  final _changesCtrl =
      StreamController<({String userId, bool isOnline})>.broadcast();

  MeshPeerEligibilityWatcher({
    required this.transport,
    required this.contactKeyStore,
  });

  Stream<({String userId, bool isOnline})> get userChanges =>
      _changesCtrl.stream;

  void start() {
    _discSub ??= transport.discoveries.listen(_onDiscovered);
    _lossSub ??= transport.losses.listen(_onLost);
  }

  Future<void> dispose() async {
    await _discSub?.cancel();
    await _lossSub?.cancel();
    _discSub = null;
    _lossSub = null;
    if (!_changesCtrl.isClosed) await _changesCtrl.close();
    _onlineDevices.clear();
  }

  bool isUserOnline(String userId) =>
      _onlineDevices[userId]?.isNotEmpty ?? false;

  bool get hasAnyOnlinePeer => _onlineDevices.isNotEmpty;
  int get onlinePeerCount => _onlineDevices.length;

  String? _userIdForDevice(PeerId devicePk) {
    final userPk = contactKeyStore.lookupUserByDevice(devicePk);
    if (userPk == null) return null;
    final userPkHex = userPk.toHex();
    for (final (userId, mappedUserPk) in contactKeyStore.allUserIdMappings()) {
      if (mappedUserPk.toHex() == userPkHex) return userId;
    }
    return null;
  }

  void _onDiscovered(PeerDiscovered event) {
    final userId = _userIdForDevice(event.peerId);
    if (userId == null) return;
    final set = _onlineDevices.putIfAbsent(userId, () => <PeerId>{});
    final wasEmpty = set.isEmpty;
    set.add(event.peerId);
    if (wasEmpty && !_changesCtrl.isClosed) {
      _changesCtrl.add((userId: userId, isOnline: true));
    }
  }

  void _onLost(PeerLost event) {
    String? hitUserId;
    for (final entry in _onlineDevices.entries) {
      if (entry.value.contains(event.peerId)) {
        hitUserId = entry.key;
        break;
      }
    }
    if (hitUserId == null) return;
    final set = _onlineDevices[hitUserId]!;
    set.remove(event.peerId);
    if (set.isEmpty) {
      _onlineDevices.remove(hitUserId);
      if (!_changesCtrl.isClosed) {
        _changesCtrl.add((userId: hitUserId, isOnline: false));
      }
    }
  }
}
