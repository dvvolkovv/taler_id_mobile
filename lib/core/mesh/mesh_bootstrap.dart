import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../di/service_locator.dart';
import '../storage/secure_storage_service.dart';
import '../../features/mesh/presentation/bloc/mesh_status_bloc.dart';
import 'crypto/keys/contact_key_store.dart';
import 'crypto/keys/contact_key_store_hive.dart';
import 'crypto/keys/mesh_static_key.dart';
import 'crypto/keys/user_identity_key.dart';
import 'services/device_key_sync_service.dart';
import 'services/device_keys_api_client.dart';
import 'services/mesh_messaging_service.dart';

/// Phase 1g — run the mesh bootstrap for the authenticated user.
///
/// Shared by:
///   - [AuthBloc] on explicit login / register / 2FA events.
///   - [setupDependencies] at app start when a JWT is already cached.
///
/// The bootstrap is idempotent: calling it twice with the same [userId] is
/// safe. It re-registers [DeviceKeySyncService] with the real userId,
/// syncs the own device cert to the server (best-effort), starts
/// [MeshMessagingService] Bonjour/BLE advertising under
/// `taler-mesh-<userId>`, and flags [MeshStatusBloc] as running.
Future<void> runMeshBootstrap(String userId) async {
  debugPrint('[mesh-boot] start userId=$userId');
  try {
    if (sl.isRegistered<DeviceKeySyncService>()) {
      await sl.unregister<DeviceKeySyncService>();
    }
    sl.registerLazySingleton<DeviceKeySyncService>(
      () => DeviceKeySyncService(
        api: sl<DeviceKeysApiClient>(),
        store: sl<HiveContactKeyStore>(),
        inMemoryStore: sl<ContactKeyStore>(),
        userIdentityKey: sl<UserIdentityKey>(),
        meshStaticKey: sl<MeshStaticKey>(),
        myUserId: userId,
      ),
    );
    debugPrint('[mesh-boot] DeviceKeySyncService re-registered');

    try {
      await sl<DeviceKeySyncService>().registerOwnDevice();
      debugPrint('[mesh-boot] registerOwnDevice succeeded');
    } catch (e) {
      debugPrint('[mesh-boot] registerOwnDevice failed: $e');
    }

    if (sl.isRegistered<MeshMessagingService>()) {
      try {
        await sl<MeshMessagingService>()
            .start(serviceName: 'taler-mesh-$userId');
        debugPrint('[mesh-boot] MeshMessagingService.start() ok for taler-mesh-$userId');
      } catch (e) {
        debugPrint('[mesh-boot] MeshMessagingService.start() failed: $e');
      }
    } else {
      debugPrint('[mesh-boot] MeshMessagingService not registered');
    }

    try {
      sl<MeshStatusBloc>().markRunning(true);
      debugPrint('[mesh-boot] MeshStatusBloc.markRunning(true) ok');
    } catch (e) {
      debugPrint('[mesh-boot] markRunning failed: $e');
    }
  } catch (e) {
    debugPrint('[mesh-boot] bootstrap outer catch: $e');
  }
}

/// Phase 1g — check for a cached JWT and kick off [runMeshBootstrap] if one
/// exists. Called from [setupDependencies] at app start so mesh is usable
/// even when the user didn't enter credentials this session.
Future<void> runMeshBootstrapIfAuthenticated() async {
  try {
    final token = await sl<SecureStorageService>().getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('[mesh-boot] no cached token, skipping startup bootstrap');
      return;
    }
    final userId = _decodeSubFromJwt(token);
    if (userId == null) {
      debugPrint('[mesh-boot] could not decode userId from cached JWT');
      return;
    }
    await runMeshBootstrap(userId);
  } catch (e) {
    debugPrint('[mesh-boot] startup bootstrap failed: $e');
  }
}

String? _decodeSubFromJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map<String, dynamic>;
    return payload['sub'] as String?;
  } catch (_) {
    return null;
  }
}
