import 'dart:convert';

import 'package:dio/dio.dart';

import '../crypto/keys/device_cert.dart';

/// Dio wrapper for Taler ID backend device-keys endpoints.
///
/// The injected [Dio] instance must already have the project's AuthInterceptor
/// attached (JWT token header injection). This client focuses on the
/// device-key surface only.
class DeviceKeysApiClient {
  final Dio _dio;

  DeviceKeysApiClient(this._dio);

  /// POST /profile/device-keys — registers a freshly minted self-signed cert.
  Future<Map<String, dynamic>> registerDeviceKey(DeviceCert cert) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/profile/device-keys',
      data: {
        'devicePk': cert.devicePk,
        'algorithm': cert.algorithm,
        'validUntilEpochMs': cert.validUntilEpochMs,
        'signature': cert.signature,
        'certificate': cert.toCanonicalJsonWithoutSignature(),
      },
    );
    return res.data!;
  }

  /// GET /profile/contacts/:userId/keys — returns the peer's current active
  /// device certs.
  Future<List<DeviceCert>> getContactKeys(String contactUserId) async {
    final res = await _dio.get<List<dynamic>>(
      '/profile/contacts/$contactUserId/keys',
    );
    return res.data!.map((raw) {
      final row = raw as Map<String, dynamic>;
      // The server returns the canonical certificate JSON string in `certificate`;
      // parse it to get the signed content, then attach the server-returned signature.
      final certJsonStr = row['certificate'] as String;
      final inner = jsonDecode(certJsonStr) as Map<String, dynamic>;
      return DeviceCert(
        devicePk: inner['devicePk'] as String,
        userId: inner['userId'] as String,
        algorithm: inner['algorithm'] as String,
        validUntilEpochMs: inner['validUntilEpochMs'] as int,
        signature: row['signature'] as String,
      );
    }).toList();
  }

  /// POST /profile/device-keys/:id/revoke — revokes own key by id.
  Future<void> revokeDeviceKey(String keyId, {String? reason}) async {
    await _dio.post<dynamic>(
      '/profile/device-keys/$keyId/revoke',
      data: reason != null ? {'reason': reason} : <String, dynamic>{},
    );
  }
}
