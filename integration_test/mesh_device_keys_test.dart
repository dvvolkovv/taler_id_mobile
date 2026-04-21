// Phase 1b integration test: register own device key + contact fetches it.
// Runs against staging.id.taler.tirol using real network.
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
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
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
  // Decode JWT payload (base64url, no verification) to extract sub = userId.
  final parts = token.split('.');
  final payload = jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  ) as Map<String, dynamic>;
  return (token: token, userId: payload['sub'] as String);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Phase 1b — register own key + user2 fetches it from DEV',
    (tester) async {
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter('${appDir.path}/mesh_integ_test');

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

      final signing = await DeviceKey.generate();
      final mesh = await MeshStaticKey.generate();
      final devicePk = PeerId(mesh.publicKey);

      final store1 = await HiveContactKeyStore.open(boxName: 'integ-u1-${DateTime.now().millisecondsSinceEpoch}');
      final svc1 = DeviceKeySyncService(
        api: DeviceKeysApiClient(dio1),
        store: store1,
        signingKey: signing,
        meshStaticKey: mesh,
        myUserId: u1.userId,
      );

      // user1 registers its device key.
      await svc1.registerOwnDevice();

      // user2 fetches user1's keys.
      final store2 = await HiveContactKeyStore.open(boxName: 'integ-u2-${DateTime.now().millisecondsSinceEpoch}');
      final svc2 = DeviceKeySyncService(
        api: DeviceKeysApiClient(dio2),
        store: store2,
        signingKey: await DeviceKey.generate(),
        meshStaticKey: await MeshStaticKey.generate(),
        myUserId: u2.userId,
      );
      await svc2.fetchContactKeys(u1.userId);

      // user1's mesh pk must now be known to user2.
      expect(
        store2.isKnownDevice(devicePk),
        isTrue,
        reason: "user2 should have user1's newly registered device pk",
      );

      await store1.close();
      await store2.close();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
