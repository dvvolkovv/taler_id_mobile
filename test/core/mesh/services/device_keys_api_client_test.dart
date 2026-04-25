import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/services/device_keys_api_client.dart';

class _MockInterceptor extends Interceptor {
  final Map<String, dynamic> responses;
  final List<String> callLog = [];
  final List<RequestOptions> capturedRequests = [];
  _MockInterceptor(this.responses);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final key = '${options.method} ${options.path}';
    callLog.add(key);
    capturedRequests.add(options);
    if (responses.containsKey(key)) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: responses[key],
      ));
    } else {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            data: {'error': 'no mock for $key'},
          ),
        ),
      );
    }
  }
}

void main() {
  group('DeviceKeysApiClient', () {
    test('registerDeviceKey posts userPk embedded in certificate field', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://fake.test'));
      final mock = _MockInterceptor({
        'POST /profile/device-keys': {
          'id': 'dk-1',
          'userId': 'user-1',
          'devicePk': 'ab' * 32,
          'userPk': 'cd' * 32,
          'algorithm': 'X25519',
          'validUntil': '2030-01-01T00:00:00.000Z',
          'certificate': '{}',
          'signature': 'ff' * 64,
          'revokedAt': null,
          'createdAt': '2026-04-22T00:00:00.000Z',
        },
      });
      dio.interceptors.add(mock);
      final client = DeviceKeysApiClient(dio);
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        userPk: 'cd' * 32,
        algorithm: 'X25519',
        validUntilEpochMs: 1800000000000,
        signature: 'ff' * 64,
      );
      final result = await client.registerDeviceKey(cert);
      expect(result['id'], 'dk-1');
      expect(result['userPk'], 'cd' * 32);

      // Verify the embedded certificate JSON contains userPk.
      expect(mock.capturedRequests, hasLength(1));
      final body = mock.capturedRequests.single.data as Map<String, dynamic>;
      expect(body['devicePk'], cert.devicePk);
      expect(body['certificate'], equals(cert.toCanonicalJsonWithoutSignature()));
      expect((body['certificate'] as String).contains('"userPk"'), isTrue);
    });

    test('getContactKeys parses userPk from embedded certificate', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://fake.test'));
      final innerCert = {
        'algorithm': 'X25519',
        'devicePk': 'cd' * 32,
        'userId': 'user-2',
        'userPk': 'ef' * 32,
        'validUntilEpochMs': 1800000000000,
      };
      dio.interceptors.add(_MockInterceptor({
        'GET /profile/contacts/user-2/keys': [
          {
            'id': 'dk-2',
            'userId': 'user-2',
            'devicePk': 'cd' * 32,
            'userPk': 'ef' * 32,
            'algorithm': 'X25519',
            'validUntil': '2030-01-01T00:00:00.000Z',
            'certificate': jsonEncode(innerCert),
            'signature': 'aa' * 64,
            'revokedAt': null,
            'createdAt': '2026-04-22T00:00:00.000Z',
          }
        ],
      }));
      final client = DeviceKeysApiClient(dio);
      final certs = await client.getContactKeys('user-2');
      expect(certs, hasLength(1));
      expect(certs.first.devicePk, 'cd' * 32);
      expect(certs.first.userId, 'user-2');
      expect(certs.first.userPk, 'ef' * 32);
      expect(certs.first.signature, 'aa' * 64);
    });

    test('getContactKeys tolerates Phase 1b cert without userPk', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://fake.test'));
      final innerLegacy = {
        'algorithm': 'X25519',
        'devicePk': 'cd' * 32,
        'userId': 'user-2',
        'validUntilEpochMs': 1800000000000,
      };
      dio.interceptors.add(_MockInterceptor({
        'GET /profile/contacts/user-2/keys': [
          {
            'id': 'dk-legacy',
            'userId': 'user-2',
            'devicePk': 'cd' * 32,
            'userPk': null,
            'algorithm': 'X25519',
            'validUntil': '2030-01-01T00:00:00.000Z',
            'certificate': jsonEncode(innerLegacy),
            'signature': 'aa' * 64,
            'revokedAt': null,
            'createdAt': '2026-04-22T00:00:00.000Z',
          }
        ],
      }));
      final client = DeviceKeysApiClient(dio);
      final certs = await client.getContactKeys('user-2');
      expect(certs, hasLength(1));
      expect(certs.first.userPk, isNull);
    });

    test('revokeDeviceKey POSTs with reason', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://fake.test'));
      final mock = _MockInterceptor({
        'POST /profile/device-keys/dk-1/revoke': {'id': 'dk-1', 'revokedAt': '2026-04-22T00:00:00.000Z'},
      });
      dio.interceptors.add(mock);
      final client = DeviceKeysApiClient(dio);
      await client.revokeDeviceKey('dk-1', reason: 'rotation');
      expect(mock.callLog, ['POST /profile/device-keys/dk-1/revoke']);
    });
  });
}
