import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/cert_signer.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/user_identity_key.dart';
import 'package:taler_id_mobile/core/mesh/services/device_key_sync_service.dart';
import 'package:taler_id_mobile/core/mesh/services/device_keys_api_client.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

/// In-memory fake of [DeviceKeysApiClient].
class _FakeApi implements DeviceKeysApiClient {
  final List<DeviceCert> _ownRegistered = [];
  final Map<String, List<DeviceCert>> _contactStore = {};
  int registerCalls = 0;

  @override
  Future<Map<String, dynamic>> registerDeviceKey(DeviceCert cert) async {
    registerCalls++;
    _ownRegistered.add(cert);
    return {'id': 'dk-${_ownRegistered.length}'};
  }

  @override
  Future<List<DeviceCert>> getContactKeys(String contactUserId) async =>
      List.unmodifiable(_contactStore[contactUserId] ?? const []);

  @override
  Future<void> revokeDeviceKey(String keyId, {String? reason}) async {}

  void seedContactKeys(String userId, List<DeviceCert> certs) {
    _contactStore[userId] = certs;
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('registerOwnDevice signs cert with UserIdentityKey and posts it',
      () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-1');
    final identity = await UserIdentityKey.generate();
    final mesh = await MeshStaticKey.generate();
    final service = DeviceKeySyncService(
      api: api,
      store: store,
      userIdentityKey: identity,
      meshStaticKey: mesh,
      myUserId: 'user-1',
    );
    await service.registerOwnDevice();
    expect(api.registerCalls, 1);
    await store.close();
  });

  test('fetchContactKeys stores valid cert keyed by real userPk', () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-2');

    // Seed a valid cert from another device.
    final otherIdentity = await UserIdentityKey.generate();
    final otherMesh = await MeshStaticKey.generate();
    final otherSigner = CertSigner(userIdentityKey: otherIdentity);
    final validCert = await otherSigner.sign(
      meshPublicKey: otherMesh.publicKey,
      userId: 'user-2',
      validUntilEpochMs: DateTime.now()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
    );
    api.seedContactKeys('user-2', [validCert]);

    final myIdentity = await UserIdentityKey.generate();
    final myMesh = await MeshStaticKey.generate();
    final service = DeviceKeySyncService(
      api: api,
      store: store,
      userIdentityKey: myIdentity,
      meshStaticKey: myMesh,
      myUserId: 'user-1',
    );
    await service.fetchContactKeys('user-2');

    final devicePeer = PeerId.fromHex(validCert.devicePk);
    expect(store.isKnownDevice(devicePeer), isTrue);

    // userPk lookup must match the real user identity pk, not a UUID placeholder.
    final lookedUp = store.lookupUserByDevice(devicePeer);
    final expectedUserPkHex = _hex(otherIdentity.publicKey);
    expect(lookedUp?.toHex(), equals(expectedUserPkHex));

    await store.close();
  });

  test('fetchContactKeys drops cert with invalid signature', () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-3');

    // Produce a valid cert then tamper with userId — signature no longer matches.
    final identity = await UserIdentityKey.generate();
    final mesh = await MeshStaticKey.generate();
    final signer = CertSigner(userIdentityKey: identity);
    final cert = await signer.sign(
      meshPublicKey: mesh.publicKey,
      userId: 'user-2',
      validUntilEpochMs: DateTime.now()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
    );
    final tampered = DeviceCert(
      devicePk: cert.devicePk,
      userId: 'evil-attacker',
      userPk: cert.userPk,
      algorithm: cert.algorithm,
      validUntilEpochMs: cert.validUntilEpochMs,
      signature: cert.signature,
    );
    api.seedContactKeys('user-2', [tampered]);

    final service = DeviceKeySyncService(
      api: api,
      store: store,
      userIdentityKey: await UserIdentityKey.generate(),
      meshStaticKey: await MeshStaticKey.generate(),
      myUserId: 'user-1',
    );
    await service.fetchContactKeys('user-2');

    expect(store.isKnownDevice(PeerId.fromHex(tampered.devicePk)), isFalse);
    await store.close();
  });

  test('fetchContactKeys stores Phase 1b cert (userPk null) via server-trust fallback',
      () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-4');

    // Simulate a legacy Phase 1b cert: userPk null.
    final legacy = DeviceCert(
      devicePk: 'ab' * 32,
      userId: 'user-legacy',
      userPk: null,
      algorithm: 'X25519',
      validUntilEpochMs: DateTime.now()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
      signature: 'ff' * 64,
    );
    api.seedContactKeys('user-legacy', [legacy]);

    final service = DeviceKeySyncService(
      api: api,
      store: store,
      userIdentityKey: await UserIdentityKey.generate(),
      meshStaticKey: await MeshStaticKey.generate(),
      myUserId: 'user-1',
    );
    await service.fetchContactKeys('user-legacy');

    expect(store.isKnownDevice(PeerId.fromHex('ab' * 32)), isTrue);
    await store.close();
  });
}

String _hex(List<int> bytes) {
  final buf = StringBuffer();
  for (final b in bytes) {
    buf.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}
