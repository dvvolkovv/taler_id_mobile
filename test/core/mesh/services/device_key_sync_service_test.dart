import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/services/device_key_sync_service.dart';
import 'package:taler_id_mobile/core/mesh/services/device_keys_api_client.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

/// In-memory fake for tests — satisfies DeviceKeysApiClient surface.
class _FakeApi implements DeviceKeysApiClient {
  final List<DeviceCert> ownRegistered = [];
  final Map<String, List<DeviceCert>> _contactStore = {};
  int registerCalls = 0;

  @override
  Future<Map<String, dynamic>> registerDeviceKey(DeviceCert cert) async {
    registerCalls++;
    ownRegistered.add(cert);
    return {'id': 'dk-${ownRegistered.length}'};
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

  test('registerOwnDevice signs cert and posts it', () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-1');
    final signing = await DeviceKey.generate();
    final mesh = await MeshStaticKey.generate();
    final service = DeviceKeySyncService(
      api: api,
      store: store,
      signingKey: signing,
      meshStaticKey: mesh,
      myUserId: 'user-1',
    );
    await service.registerOwnDevice();
    expect(api.registerCalls, 1);
    expect(api.ownRegistered.first.userId, 'user-1');
    expect(api.ownRegistered.first.devicePk.length, 64);
    await store.close();
  });

  test('fetchContactKeys stores certs locally', () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-2');
    final signing = await DeviceKey.generate();
    final mesh = await MeshStaticKey.generate();
    final service = DeviceKeySyncService(
      api: api,
      store: store,
      signingKey: signing,
      meshStaticKey: mesh,
      myUserId: 'user-1',
    );
    final cert = DeviceCert(
      devicePk: 'ab' * 32,
      userId: 'user-2',
      algorithm: 'X25519',
      validUntilEpochMs: DateTime.now()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
      signature: 'ff' * 64,
    );
    api.seedContactKeys('user-2', [cert]);

    await service.fetchContactKeys('user-2');
    expect(
      store.isKnownDevice(PeerId.fromHex(cert.devicePk)),
      isTrue,
    );
    await store.close();
  });

  test('fetchContactKeys with empty response is a no-op', () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-3');
    final signing = await DeviceKey.generate();
    final mesh = await MeshStaticKey.generate();
    final service = DeviceKeySyncService(
      api: api,
      store: store,
      signingKey: signing,
      meshStaticKey: mesh,
      myUserId: 'user-1',
    );
    // No seed → server returns empty list
    await service.fetchContactKeys('user-nobody');
    // No assertion errors thrown; store stays empty.
    await store.close();
  });
}
