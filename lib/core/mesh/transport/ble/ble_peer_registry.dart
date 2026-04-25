import '../peer_id.dart';

enum BleLinkState {
  idle,
  connecting,
  connected,
}

/// Tracks per-peer BLE connection state and enforces the lexicographic
/// tiebreak that decides which side initiates when both discover the
/// other simultaneously.
///
/// Rule: the peer with the smaller `devicePk` hex string initiates as
/// central; the other waits for an incoming connection in the peripheral
/// role.
class BlePeerRegistry {
  final PeerId selfPk;
  final Map<PeerId, BleLinkState> _state = {};

  BlePeerRegistry({required this.selfPk});

  /// True iff this device should initiate the BLE connect to [peer] once
  /// both sides have discovered each other. False for equal (self) or
  /// for the side that must wait.
  bool shouldInitiate(PeerId peer) {
    final mine = selfPk.toHex();
    final theirs = peer.toHex();
    return mine.compareTo(theirs) < 0;
  }

  BleLinkState stateOf(PeerId peer) => _state[peer] ?? BleLinkState.idle;

  void mark(PeerId peer, BleLinkState state) {
    _state[peer] = state;
  }

  void forget(PeerId peer) {
    _state.remove(peer);
  }

  Iterable<PeerId> allConnected() => _state.entries
      .where((e) => e.value == BleLinkState.connected)
      .map((e) => e.key);
}
