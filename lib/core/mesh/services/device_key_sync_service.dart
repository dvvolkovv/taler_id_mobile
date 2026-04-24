import 'package:flutter/foundation.dart';

import '../crypto/keys/cert_signer.dart';
import '../crypto/keys/contact_key_store.dart';
import '../crypto/keys/contact_key_store_hive.dart';
import '../crypto/keys/mesh_static_key.dart';
import '../crypto/keys/user_identity_key.dart';
import '../transport/peer_id.dart';
import 'device_keys_api_client.dart';

/// Coordinates backend device-key sync with local stores.
///
/// Phase 1c: certs are signed by the permanent [UserIdentityKey] and
/// persisted in [HiveContactKeyStore] on fetch.
/// Phase 1f: verified certs are additionally mirrored into the in-memory
/// [ContactKeyStore] used by MeshMessagingService for Noise IK. Without
/// this bridge, outbound mesh messages fail with "unknown device" even
/// though the cert is in Hive.
class DeviceKeySyncService {
  final DeviceKeysApiClient api;
  final HiveContactKeyStore store;
  final ContactKeyStore inMemoryStore;
  final UserIdentityKey userIdentityKey;
  final MeshStaticKey meshStaticKey;
  final String myUserId;
  final Duration certValidity;

  DeviceKeySyncService({
    required this.api,
    required this.store,
    required this.inMemoryStore,
    required this.userIdentityKey,
    required this.meshStaticKey,
    required this.myUserId,
    this.certValidity = const Duration(days: 30),
  });

  /// Mint a fresh self-signed cert and POST it to the server.
  Future<void> registerOwnDevice() async {
    final signer = CertSigner(userIdentityKey: userIdentityKey);
    final cert = await signer.sign(
      meshPublicKey: meshStaticKey.publicKey,
      userId: myUserId,
      validUntilEpochMs:
          DateTime.now().add(certValidity).millisecondsSinceEpoch,
    );
    await api.registerDeviceKey(cert);
  }

  /// Fetch the contact's active certs. Phase 1f: verified certs are also
  /// mirrored into the in-memory [ContactKeyStore] so Noise IK handshakes
  /// can find the devicePk for this contact.
  Future<void> fetchContactKeys(String contactUserId) async {
    final certs = await api.getContactKeys(contactUserId);
    if (certs.isEmpty) {
      debugPrint('[mesh-sync] no keys for $contactUserId');
      return;
    }
    for (final cert in certs) {
      if (cert.userPk != null) {
        final ok = await CertSigner.verifyWithEmbeddedUserPk(cert: cert);
        if (!ok) {
          debugPrint(
            '[mesh-sync] dropping cert with bad signature devicePk=${cert.devicePk}',
          );
          continue;
        }
        final userPeer = PeerId.fromHex(cert.userPk!);
        await store.addContactCerts(userPk: userPeer, certs: [cert]);

        // Phase 1f — mirror verified cert into the in-memory ContactKeyStore
        // used by MeshMessagingService for Noise IK. Inside the verified
        // branch so we never trust a bad cert.
        try {
          final devicePeer = PeerId.fromHex(cert.devicePk);
          inMemoryStore.addContact(
            userPk: userPeer,
            devicePks: [devicePeer],
          );
        } catch (e) {
          debugPrint(
            '[mesh-sync] failed to mirror devicePk into in-memory store: $e',
          );
        }
      } else {
        // Phase 1b legacy cert: no userPk to verify against. Trust the server
        // for backward compat; key the entry by a UUID-derived PeerId. NOT
        // mirrored into ContactKeyStore — no real userPk to key by.
        final fallbackUserPk = _derivePlaceholderUserPk(contactUserId);
        await store.addContactCerts(userPk: fallbackUserPk, certs: [cert]);
      }
    }

    // Phase 1e — persist the Taler ID userId → userPk mapping so the
    // messenger layer can find this contact's identity key.
    for (final cert in certs) {
      if (cert.userPk != null && cert.userPk!.isNotEmpty) {
        try {
          await store.putContactUserIdMapping(
            contactUserId: contactUserId,
            userPk: PeerId.fromHex(cert.userPk!),
          );
          break;
        } catch (_) {
          // malformed hex — skip and try next cert
        }
      }
    }
  }

  PeerId _derivePlaceholderUserPk(String userId) {
    final bytes = Uint8List(32);
    final utf = userId.codeUnits;
    for (var i = 0; i < utf.length && i < 32; i++) {
      bytes[i] = utf[i] & 0xFF;
    }
    return PeerId(bytes);
  }
}
