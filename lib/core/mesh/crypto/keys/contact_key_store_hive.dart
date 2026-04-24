import 'dart:convert';

import 'package:hive/hive.dart';

import '../../transport/peer_id.dart';
import 'device_cert.dart';

/// Hive-persisted store of trusted contact device certs.
///
/// Storage format (per Hive box entry):
///   key   = devicePk hex (lowercase)
///   value = JSON-encoded { userPk: hex, cert: DeviceCert.toJson }
///
/// Provides the same lookup semantics as the Phase 1a in-memory
/// `ContactKeyStore`, but survives app restarts.
class HiveContactKeyStore {
  final Box<String> _box;

  HiveContactKeyStore._(this._box);

  static Future<HiveContactKeyStore> open({
    required String boxName,
  }) async {
    final box = await Hive.openBox<String>(boxName);
    return HiveContactKeyStore._(box);
  }

  Future<void> addContactCerts({
    required PeerId userPk,
    required List<DeviceCert> certs,
  }) async {
    for (final cert in certs) {
      final entry = jsonEncode({
        'userPk': userPk.toHex(),
        'cert': cert.toJson(),
      });
      await _box.put(cert.devicePk.toLowerCase(), entry);
    }
  }

  bool isKnownDevice(PeerId devicePk) =>
      _box.containsKey(devicePk.toHex().toLowerCase());

  PeerId? lookupUserByDevice(PeerId devicePk) {
    final raw = _box.get(devicePk.toHex().toLowerCase());
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return PeerId.fromHex(map['userPk'] as String);
  }

  DeviceCert? lookupCertByDevice(PeerId devicePk) {
    final raw = _box.get(devicePk.toHex().toLowerCase());
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return DeviceCert.fromJson(map['cert'] as Map<String, dynamic>);
  }

  List<PeerId> devicesFor(PeerId userPk) {
    final userHex = userPk.toHex();
    final devices = <PeerId>[];
    for (final entry in _box.toMap().entries) {
      // Skip the userId-mapping entries (Phase 1e) — they are plain hex strings,
      // not JSON-encoded cert objects.
      if (entry.key is String &&
          (entry.key as String).startsWith('userId:')) continue;
      try {
        final map = jsonDecode(entry.value) as Map<String, dynamic>;
        if (map['userPk'] == userHex) {
          devices.add(PeerId.fromHex(
              (map['cert'] as Map<String, dynamic>)['devicePk'] as String));
        }
      } catch (_) {
        // malformed entry — skip
      }
    }
    return devices;
  }

  Future<void> removeDevice(PeerId devicePk) async {
    await _box.delete(devicePk.toHex().toLowerCase());
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> close() async {
    await _box.close();
  }

  // ---------------------------------------------------------------------------
  // Phase 1e — Taler ID contactUserId ↔ userPk (Ed25519 hex) mapping.
  //
  // Keys use the prefix `userId:` which never collides with the device-cert
  // entries (those are keyed by lowercase hex devicePk, containing only
  // `[0-9a-f]` — never `:` characters).
  // ---------------------------------------------------------------------------

  /// Store a Taler ID contactUserId → userPk (Ed25519 hex) mapping.
  /// Called by DeviceKeySyncService.fetchContactKeys after it learns the
  /// userPk from server-returned certs.
  Future<void> putContactUserIdMapping({
    required String contactUserId,
    required PeerId userPk,
  }) async {
    await _box.put('userId:$contactUserId', userPk.toHex());
  }

  /// Returns the userPk (Ed25519 hex) for a Taler ID contactUserId, or null.
  PeerId? userPkForContactUserId(String contactUserId) {
    final hex = _box.get('userId:$contactUserId');
    if (hex == null) return null;
    try {
      return PeerId.fromHex(hex);
    } catch (_) {
      return null;
    }
  }

  /// List all (contactUserId, userPk) mappings stored by
  /// putContactUserIdMapping. O(n) scan of the `userId:` prefixed keys.
  Iterable<(String, PeerId)> allUserIdMappings() sync* {
    for (final key in _box.keys) {
      if (key is! String) continue;
      if (!key.startsWith('userId:')) continue;
      final userId = key.substring('userId:'.length);
      final hex = _box.get(key);
      if (hex == null) continue;
      try {
        yield (userId, PeerId.fromHex(hex));
      } catch (_) {
        // skip malformed
      }
    }
  }
}
