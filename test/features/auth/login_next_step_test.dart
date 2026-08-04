import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:taler_id_mobile/features/auth/data/repositories/auth_repository_impl.dart';

class _MockDio extends Mock implements DioClient {}

class _MockStorage extends Mock implements SecureStorageService {}

/// Датасорс подменяем целиком: под тестом форма ответа бэкенда, а не HTTP.
class _StubRemote extends AuthRemoteDataSource {
  _StubRemote(this.response) : super(_MockDio());

  final Map<String, dynamic> response;
  Map<String, dynamic>? sentVerifyBody;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async =>
      response;
}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
    when(() => storage.saveUserId(any())).thenAnswer((_) async {});
  });

  AuthRepositoryImpl repoFor(Map<String, dynamic> response) =>
      AuthRepositoryImpl(remote: _StubRemote(response), storage: storage);

  group('login response shape', () {
    // Бэкенд отвечает `{ next: '2fa', challengeToken }`. Клиент до 1.1.24
    // читал несуществующие `requires2FA`/`tempToken`, проваливался мимо ветки
    // и падал на приведении null к String — то есть вход с включённым TOTP
    // не работал вообще.
    test('a TOTP challenge is recognised and carries the backend field', () async {
      final repo = repoFor({'next': '2fa', 'challengeToken': 'chal-123'});

      await expectLater(
        repo.login(email: 'a@b.c', password: 'pw'),
        throwsA(isA<TwoFARequiredException>()
            .having((e) => e.challengeToken, 'challengeToken', 'chal-123')
            .having((e) => e.email, 'email', 'a@b.c')),
      );
    });

    test('a pending device approval is recognised', () async {
      final repo = repoFor({
        'next': 'device_approval',
        'approvalToken': 'tok-456',
        'approverCount': 2,
        'emailAvailable': true,
        'expiresIn': 600,
      });

      await expectLater(
        repo.login(email: 'a@b.c', password: 'pw'),
        throwsA(isA<DeviceApprovalRequiredException>()
            .having((e) => e.approvalToken, 'approvalToken', 'tok-456')
            .having((e) => e.approverCount, 'approverCount', 2)
            .having((e) => e.emailAvailable, 'emailAvailable', true)
            .having((e) => e.expiresIn, 'expiresIn', 600)),
      );
    });

    test('an ordinary login still returns tokens', () async {
      final repo = repoFor({
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
      });

      final tokens = await repo.login(email: 'a@b.c', password: 'pw');

      expect(tokens.accessToken, 'access-1');
      expect(tokens.refreshToken, 'refresh-1');
    });

    test('an unknown next step fails loudly rather than crashing on null',
        () async {
      final repo = repoFor({'next': 'something-we-do-not-know'});

      await expectLater(
        repo.login(email: 'a@b.c', password: 'pw'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
