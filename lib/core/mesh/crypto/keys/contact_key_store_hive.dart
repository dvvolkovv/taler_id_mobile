import 'dart:convert';

import 'package:hive/hive.dart';

import '../../transport/peer_id.dart';
import '../../../../core/voice/mesh_peer_eligibility_watcher.dart';
import 'contact_key_store.dart';
import 'device_cert.dart';

/// Hive-persisted store of trusted contact device certs.
///
/// Storage format (per Hive box entry):
///   key   = devicePk hex (lowercase)
///   value = JSON-encoded { userPk: hex, cert: DeviceCert.toJson }
///
/// Provides the same lookup semantics as the Phase 1a in-memory
/// `ContactKeyStore`, but survives app restarts.
class HiveContactKeyStore implements ContactKeyStoreLookup {
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

  @override
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
  ///
  /// Phase 3d hotfix: server data sometimes returns multiple verified certs
  /// for one contactUserId where the embedded userPk differs (user-rotated
  /// identity, multi-account history). We persist EVERY unique verified
  /// userPk under a parallel `userIdAlt:contactUserId:userPkHex` key so that
  /// `allUserIdMappings()` yields each pair. Without this, lookups by an
  /// alternate userPk returned `null` and the mesh adapter dropped envelopes
  /// from the second device with `inbound from unknown userPk, dropped`.
  Future<void> putContactUserIdMapping({
    required String contactUserId,
    required PeerId userPk,
  }) async {
    final hex = userPk.toHex();
    final primaryKey = 'userId:$contactUserId';
    if (_box.get(primaryKey) == null) {
      // First call — set the canonical primary mapping (preserves
      // existing call sites that rely on `userPkForContactUserId`).
      await _box.put(primaryKey, hex);
    }
    // Always record this userPk in the alt set so subsequent calls with
    // a different userPk for the same contact don't get lost.
    await _box.put('userIdAlt:$contactUserId:$hex', hex);
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
  /// putContactUserIdMapping. Yields the primary mapping plus any alts
  /// recorded for contacts whose server certs reference multiple userPks.
  ///
  /// De-duplicates by (userId, userPkHex) because putContactUserIdMapping
  /// always writes the same userPk under BOTH the primary `userId:` key AND
  /// the alt `userIdAlt:userId:userPkHex` key — without de-dup, every single
  /// call to putContactUserIdMapping would surface as two identical
  /// mappings here. Distinct alt userPks for the same userId (the
  /// rotated-identity case the alt-set was added for) still surface
  /// because they have different userPkHex.
  @override
  Iterable<(String, PeerId)> allUserIdMappings() sync* {
    final seen = <String>{};
    for (final key in _box.keys) {
      if (key is! String) continue;
      String? userId;
      String? hex;
      if (key.startsWith('userId:')) {
        userId = key.substring('userId:'.length);
        hex = _box.get(key);
      } else if (key.startsWith('userIdAlt:')) {
        // Format: userIdAlt:<contactUserId>:<userPkHex>
        final rest = key.substring('userIdAlt:'.length);
        final colon = rest.lastIndexOf(':');
        if (colon <= 0) continue;
        userId = rest.substring(0, colon);
        hex = rest.substring(colon + 1);
      }
      if (userId == null || hex == null) continue;
      if (!seen.add('$userId:$hex')) continue;
      try {
        yield (userId, PeerId.fromHex(hex));
      } catch (_) {/* skip malformed */}
    }
  }

  /// Phase 1g — populate an in-memory [ContactKeyStore] with every
  /// (userPk → [devicePks]) mapping currently cached in Hive. Called once
  /// at app start so Noise IK handshakes succeed even when the network
  /// fetch of contact keys has never completed (airplane mode, server
  /// down, or first-launch after install with cached state).
  void bridgeIntoInMemory(ContactKeyStore inMemory) {
    // Walk userId: entries to find unique userPks, then resolve their
    // device lists via devicesFor.
    final seenUserPks = <String>{};
    for (final (_, userPk) in allUserIdMappings()) {
      final hex = userPk.toHex();
      if (!seenUserPks.add(hex)) continue;
      final devices = devicesFor(userPk);
      if (devices.isEmpty) continue;
      inMemory.addContact(userPk: userPk, devicePks: devices);
    }
  }
}
