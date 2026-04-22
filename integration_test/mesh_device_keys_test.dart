// Phase 1c integration test: register own device key with userPk + contact
// fetches and verifies it. Runs against staging.id.taler.tirol.
//
// flutter test integration_test/mesh_device_keys_test.dart \
//   --flavor dev -t lib/main_dev.dart \
//   --dart-define=FLAVOR=dev \
//   --dart-define=BASE_URL=https://staging.id.taler.tirol \
//   -d emulator-5554

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/user_identity_key.dart';
import 'package:taler_id_mobile/core/mesh/services/device_key_sync_service.dart';
import 'package:taler_id_mobile/core/mesh/services/device_keys_api_client.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

const _baseUrl = 'https://staging.id.taler.tirol';
const _user1Email = 'integration_test@taler-test.com';
const _user1Password = 'IntegrationTest123!';
const _user2Email = 'integration_test_2@taler-test.com';
const _user2Password = 'IntegrationTest123!';

Future<({String token, String userId})> _login(
    Dio dio, String email, String password) async {
  final res = await dio.post<Map<String, dynamic>>(
    '/auth/login',
    data: {'email': email, 'password': password},
  );
  final token = res.data!['accessToken'] as String;
  final parts = token.split('.');
  final payload = jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  ) as Map<String, dynamic>;
  return (token: token, userId: payload['sub'] as String);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Phase 1c — register own key (userPk) + user2 fetches and verifies it',
    (tester) async {
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter('${appDir.path}/mesh_integ_test_c');

      final bootstrapDio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final u1 = await _login(bootstrapDio, _user1Email, _user1Password);
      final u2 = await _login(bootstrapDio, _user2Email, _user2Password);

      final dio1 = Dio(BaseOptions(
        baseUrl: _baseUrl,
        headers: {'Authorization': 'Bearer ${u1.token}'},
      ));
      final dio2 = Dio(BaseOptions(
        baseUrl: _baseUrl,
        headers: {'Authorization': 'Bearer ${u2.token}'},
      ));

      final identity1 = await UserIdentityKey.generate();
      final mesh1 = await MeshStaticKey.generate();
      final devicePk = PeerId(mesh1.publicKey);

      final stamp = DateTime.now().millisecondsSinceEpoch;
      final store1 = await HiveContactKeyStore.open(boxName: 'integ-u1-c-$stamp');
      final svc1 = DeviceKeySyncService(
        api: DeviceKeysApiClient(dio1),
        store: store1,
        userIdentityKey: identity1,
        meshStaticKey: mesh1,
        myUserId: u1.userId,
      );

      await svc1.registerOwnDevice();

      final store2 = await HiveContactKeyStore.open(boxName: 'integ-u2-c-$stamp');
      final svc2 = DeviceKeySyncService(
        api: DeviceKeysApiClient(dio2),
        store: store2,
        userIdentityKey: await UserIdentityKey.generate(),
        meshStaticKey: await MeshStaticKey.generate(),
        myUserId: u2.userId,
      );
      await svc2.fetchContactKeys(u1.userId);

      // Device known (cert passed signature verification on fetch).
      expect(store2.isKnownDevice(devicePk), isTrue,
          reason: "user2 should have user1's device pk after verification");

      // The stored cert must map to user1's real userPk (not a UUID-derived placeholder).
      final looked = store2.lookupUserByDevice(devicePk);
      expect(looked?.bytes, equals(identity1.publicKey),
          reason: 'stored userPk must be user1 UserIdentityKey, not placeholder');

      await store1.close();
      await store2.close();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
