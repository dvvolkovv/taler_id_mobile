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
    for (final raw in _box.values) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['userPk'] == userHex) {
        devices.add(PeerId.fromHex(
            (map['cert'] as Map<String, dynamic>)['devicePk'] as String));
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
}
