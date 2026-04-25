import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/mesh/transport/mesh_transport.dart';
import '../../../../core/mesh/transport/peer_id.dart';
import '../../domain/entities/mesh_status.dart';

/// Reactive snapshot of the mesh transport state for UI.
///
/// Subscribes to [MeshTransport.discoveries] / [MeshTransport.losses] and
/// maintains a live map of which Taler ID contacts currently have at least
/// one devicePk visible in the mesh.
///
/// Contact resolution is supplied via callbacks so this class has no
/// direct dependency on HiveContactKeyStore / ContactsCacheService.
class MeshStatusBloc extends Cubit<MeshStatus> {
  final MeshTransport transport;
  final PeerId? Function(PeerId devicePk) lookupUserByDevice;
  final String? Function(PeerId userPk) contactUserIdForUserPk;

  StreamSubscription<PeerDiscovered>? _discoverySub;
  StreamSubscription<PeerLost>? _lossSub;

  final Map<PeerId, String> _contactUserIdByDevice = {};
  final Map<String, int> _deviceCountPerContact = {};
  int _rawPeerCount = 0;

  MeshStatusBloc({
    required this.transport,
    required this.lookupUserByDevice,
    required this.contactUserIdForUserPk,
  }) : super(const MeshStatus.initial());

  /// Start listening to transport events. Idempotent — safe to call twice.
  void start() {
    _discoverySub ??= transport.discoveries.listen(_onDiscover);
    _lossSub ??= transport.losses.listen(_onLoss);
  }

  /// Update the [MeshStatus.running] flag without touching peer state.
  void markRunning(bool running) {
    emit(state.copyWith(running: running));
  }

  void _onDiscover(PeerDiscovered d) {
    _rawPeerCount++;
    final userPk = lookupUserByDevice(d.peerId);
    if (userPk != null) {
      final userId = contactUserIdForUserPk(userPk);
      if (userId != null) {
        _contactUserIdByDevice[d.peerId] = userId;
        _deviceCountPerContact[userId] =
            (_deviceCountPerContact[userId] ?? 0) + 1;
      }
    }
    _emitSnapshot();
  }

  void _onLoss(PeerLost l) {
    _rawPeerCount = (_rawPeerCount - 1).clamp(0, 1 << 30);
    final userId = _contactUserIdByDevice.remove(l.peerId);
    if (userId != null) {
      final current = _deviceCountPerContact[userId] ?? 0;
      if (current <= 1) {
        _deviceCountPerContact.remove(userId);
      } else {
        _deviceCountPerContact[userId] = current - 1;
      }
    }
    _emitSnapshot();
  }

  void _emitSnapshot() {
    final visibility = <String, bool>{};
    for (final entry in _deviceCountPerContact.entries) {
      visibility[entry.key] = entry.value > 0;
    }
    emit(state.copyWith(
      peerCount: _rawPeerCount,
      visibilityByContactUserId: visibility,
    ));
  }

  @override
  Future<void> close() async {
    await _discoverySub?.cancel();
    await _lossSub?.cancel();
    return super.close();
  }
}
