import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/auth_interceptor.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockDio extends Mock implements Dio {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockSecureStorageService storage;
  late MockDio dio;
  late AuthInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(Options());
  });

  setUp(() {
    storage = MockSecureStorageService();
    dio = MockDio();
    interceptor = AuthInterceptor(dio: dio, storage: storage);
  });

  // ── onRequest: token attachment ─────────────────────────────────────

  group('onRequest', () {
    test('attaches Bearer token when available', () async {
      when(() => storage.getAccessToken()).thenAnswer((_) async => 'my-jwt-token');

      final options = RequestOptions(path: '/profile');
      final handler = _MockRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.nextOptions?.headers['Authorization'], 'Bearer my-jwt-token');
    });

    test('does not attach token when none stored', () async {
      when(() => storage.getAccessToken()).thenAnswer((_) async => null);

      final options = RequestOptions(path: '/profile');
      final handler = _MockRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.nextOptions?.headers['Authorization'], isNull);
    });

    test('skips auth when skipAuth extra is set', () async {
      final options = RequestOptions(path: '/auth/login')
        ..extra['skipAuth'] = true;
      final handler = _MockRequestHandler();

      await interceptor.onRequest(options, handler);

      // Should NOT call getAccessToken at all
      verifyNever(() => storage.getAccessToken());
      expect(handler.nextOptions, isNotNull);
    });
  });

  // ── onError: non-401 passes through ─────────────────────────────────

  group('onError', () {
    test('passes through non-401 errors', () async {
      final err = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/profile'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/profile'),
        ),
      );
      final handler = _MockErrorHandler();

      await interceptor.onError(err, handler);

      expect(handler.nextError, isNotNull);
      expect(handler.resolvedResponse, isNull);
    });

    test('passes through 401 on auth endpoints', () async {
      for (final path in ['/auth/refresh', '/auth/login', '/auth/register']) {
        final err = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: path),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: path),
          ),
        );
        final handler = _MockErrorHandler();

        await interceptor.onError(err, handler);

        expect(handler.nextError, isNotNull, reason: 'Should pass through 401 on $path');
      }
    });

    test('refreshes token and retries on 401', () async {
      when(() => storage.getRefreshToken())
          .thenAnswer((_) async => 'refresh-tok');
      when(() => dio.post(
            '/auth/refresh',
            data: {'refreshToken': 'refresh-tok'},
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {
              'accessToken': 'new-access-tok',
              'refreshToken': 'new-refresh-tok',
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/refresh'),
          ));
      when(() => storage.saveTokens(
            accessToken: 'new-access-tok',
            refreshToken: 'new-refresh-tok',
          )).thenAnswer((_) async {});
      when(() => storage.saveUserId(any())).thenAnswer((_) async {});

      final retryResponse = Response(
        statusCode: 200,
        data: {'name': 'John'},
        requestOptions: RequestOptions(path: '/profile'),
      );
      when(() => dio.fetch(any())).thenAnswer((_) async => retryResponse);

      final err = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/profile'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/profile'),
        ),
      );
      final handler = _MockErrorHandler();

      await interceptor.onError(err, handler);

      expect(handler.resolvedResponse?.statusCode, 200);
      verify(() => storage.saveTokens(
            accessToken: 'new-access-tok',
            refreshToken: 'new-refresh-tok',
          )).called(1);
    });

    test('clears tokens when refresh fails', () async {
      when(() => storage.getRefreshToken())
          .thenAnswer((_) async => 'old-refresh');
      when(() => dio.post(
            '/auth/refresh',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: '/auth/refresh'),
            response: Response(
              statusCode: 401,
              requestOptions: RequestOptions(path: '/auth/refresh'),
            ),
          ));
      when(() => storage.clearTokens()).thenAnswer((_) async {});

      final err = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/profile'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/profile'),
        ),
      );
      final handler = _MockErrorHandler();

      await interceptor.onError(err, handler);

      verify(() => storage.clearTokens()).called(1);
      expect(handler.nextError, isNotNull);
    });

    test('returns null token when no refresh token stored', () async {
      when(() => storage.getRefreshToken()).thenAnswer((_) async => null);

      final err = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/profile'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/profile'),
        ),
      );
      final handler = _MockErrorHandler();

      await interceptor.onError(err, handler);

      expect(handler.nextError, isNotNull);
      verifyNever(() => dio.post(any(), data: any(named: 'data'), options: any(named: 'options')));
    });
  });
}

// ── Test helpers ──────────────────────────────────────────────────────────

class _MockRequestHandler extends Mock implements RequestInterceptorHandler {
  RequestOptions? nextOptions;

  @override
  void next(RequestOptions requestOptions) {
    nextOptions = requestOptions;
  }
}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {
  DioException? nextError;
  Response? resolvedResponse;

  @override
  void next(DioException err) {
    nextError = err;
  }

  @override
  void resolve(Response response) {
    resolvedResponse = response;
  }
}
