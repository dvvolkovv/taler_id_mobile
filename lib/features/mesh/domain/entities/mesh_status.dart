import 'package:flutter/foundation.dart';

/// Snapshot of the mesh transport state used by UI.
///
/// `visibilityByContactUserId` maps a Taler ID contact userId to true
/// when at least one of their devicePks is currently discovered by the
/// mesh. Used by TransportSelector to decide if a peer is reachable.
@immutable
class MeshStatus {
  final bool running;
  final int peerCount;
  final Map<String, bool> visibilityByContactUserId;

  const MeshStatus({
    required this.running,
    required this.peerCount,
    required this.visibilityByContactUserId,
  });

  const MeshStatus.initial()
      : running = false,
        peerCount = 0,
        visibilityByContactUserId = const {};

  MeshStatus copyWith({
    bool? running,
    int? peerCount,
    Map<String, bool>? visibilityByContactUserId,
  }) =>
      MeshStatus(
        running: running ?? this.running,
        peerCount: peerCount ?? this.peerCount,
        visibilityByContactUserId:
            visibilityByContactUserId ?? this.visibilityByContactUserId,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MeshStatus) return false;
    if (running != other.running) return false;
    if (peerCount != other.peerCount) return false;
    if (visibilityByContactUserId.length !=
        other.visibilityByContactUserId.length) {
      return false;
    }
    for (final e in visibilityByContactUserId.entries) {
      if (other.visibilityByContactUserId[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        running,
        peerCount,
        Object.hashAllUnordered(
          visibilityByContactUserId.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}
