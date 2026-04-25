/// Stable identifier for a concrete [MeshTransport] implementation.
///
/// Used by [MultiTransport] to route `send()` to the highest-preference
/// transport that knows a given peer.
enum TransportId {
  /// Bonjour / mDNS over TCP — only works when both peers share a LAN,
  /// but has the highest bandwidth. Phase 1a.
  bonjour,

  /// BLE advertising + GATT. Works offline; ~100-200 Kbps. Phase 1d.
  ble,
}

/// Pure function policy for picking a transport among the set that knows
/// a given peer. Order chosen for Phase 1d: [bonjour] beats [ble] because
/// bandwidth matters more than novelty when both are available.
class TransportPreference {
  static const List<TransportId> _order = [TransportId.bonjour, TransportId.ble];

  TransportId chooseAmong(Set<TransportId> available) {
    if (available.isEmpty) {
      throw StateError('No available transports to choose from');
    }
    for (final id in _order) {
      if (available.contains(id)) return id;
    }
    // All known transports are in _order — this is unreachable while the
    // enum and _order stay in sync.
    throw StateError('Unknown transports: $available');
  }

  List<TransportId> orderedAmong(Set<TransportId> available) =>
      _order.where(available.contains).toList();
}
