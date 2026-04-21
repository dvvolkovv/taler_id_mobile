import 'package:flutter/foundation.dart';

import '../crypto/keys/cert_signer.dart';
import '../crypto/keys/contact_key_store_hive.dart';
import '../crypto/keys/device_key.dart';
import '../crypto/keys/mesh_static_key.dart';
import '../transport/peer_id.dart';
import 'device_keys_api_client.dart';

/// Coordinates backend device-key sync with local HiveContactKeyStore.
///
/// Responsibilities:
///   - On startup / login: mint a self-signed cert for this device and POST it.
///   - On contact add or FCM notification: fetch and cache that contact's certs.
class DeviceKeySyncService {
  final DeviceKeysApiClient api;
  final HiveContactKeyStore store;
  final DeviceKey signingKey;
  final MeshStaticKey meshStaticKey;
  final String myUserId;
  final Duration certValidity;

  DeviceKeySyncService({
    required this.api,
    required this.store,
    required this.signingKey,
    required this.meshStaticKey,
    required this.myUserId,
    this.certValidity = const Duration(days: 30),
  });

  /// Mint a fresh self-signed cert, send it to the server.
  Future<void> registerOwnDevice() async {
    final signer = CertSigner(signingKey: signingKey);
    final cert = await signer.sign(
      meshPublicKey: meshStaticKey.publicKey,
      userId: myUserId,
      validUntilEpochMs:
          DateTime.now().add(certValidity).millisecondsSinceEpoch,
    );
    await api.registerDeviceKey(cert);
  }

  /// Fetch peer's current active certs and persist locally.
  ///
  /// Phase 1b: `userPk` in HiveContactKeyStore is a placeholder derivation
  /// from the user id (32 bytes, padded). Phase 1c introduces proper user
  /// identity keys. Lookup by devicePk (which is what the Noise handshake
  /// actually keys on) works correctly regardless.
  Future<void> fetchContactKeys(String contactUserId) async {
    final certs = await api.getContactKeys(contactUserId);
    if (certs.isEmpty) {
      debugPrint('[mesh-sync] no keys for $contactUserId');
      return;
    }
    final userPk = _derivePlaceholderUserPk(contactUserId);
    await store.addContactCerts(userPk: userPk, certs: certs);
  }

  /// Deterministic 32-byte PeerId derived from a user UUID string.
  /// Phase 1b placeholder — Phase 1c replaces with real user identity key.
  PeerId _derivePlaceholderUserPk(String userId) {
    final bytes = Uint8List(32);
    final utf = userId.codeUnits;
    for (var i = 0; i < utf.length && i < 32; i++) {
      bytes[i] = utf[i] & 0xFF;
    }
    return PeerId(bytes);
  }
}
