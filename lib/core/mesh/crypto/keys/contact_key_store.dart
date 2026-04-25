import '../../transport/peer_id.dart';

/// Maps known user identity keys to their device public keys.
///
/// Phase 1a: pure in-memory, seeded by application (e.g. tests).
/// Phase 1b: Hive-backed with server sync.
class ContactKeyStore {
  final Map<PeerId, Set<PeerId>> _userToDevices = {};
  final Map<PeerId, PeerId> _deviceToUser = {};

  void addContact({
    required PeerId userPk,
    required List<PeerId> devicePks,
  }) {
    final set = _userToDevices.putIfAbsent(userPk, () => <PeerId>{});
    for (final d in devicePks) {
      set.add(d);
      _deviceToUser[d] = userPk;
    }
  }

  bool isKnownDevice(PeerId devicePk) => _deviceToUser.containsKey(devicePk);

  PeerId? lookupUserByDevice(PeerId devicePk) => _deviceToUser[devicePk];

  List<PeerId> devicesFor(PeerId userPk) =>
      _userToDevices[userPk]?.toList() ?? const [];

  void removeDevice(PeerId devicePk) {
    final user = _deviceToUser.remove(devicePk);
    if (user != null) {
      _userToDevices[user]?.remove(devicePk);
      if (_userToDevices[user]?.isEmpty ?? false) {
        _userToDevices.remove(user);
      }
    }
  }

  void clear() {
    _userToDevices.clear();
    _deviceToUser.clear();
  }
}
