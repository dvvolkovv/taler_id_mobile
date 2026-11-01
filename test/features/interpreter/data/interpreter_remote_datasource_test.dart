import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/features/interpreter/data/interpreter_remote_datasource.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_error.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_models.dart';

class MockDioClient extends Mock implements DioClient {}

class MockDio extends Mock implements Dio {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockDioClient http;
  late MockDio dio;
  late InterpreterRemoteDataSource ds;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(Options());
  });

  setUp(() {
    http = MockDioClient();
    dio = MockDio();
    ds = InterpreterRemoteDataSource(http);
  });

  group('catalog', () {
    test('parses the catalog on success', () async {
      when(() => http.get<InterpreterCatalog>(
            '/interpreter/languages',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((invocation) async {
        final fromJson = invocation.namedArguments[#fromJson]
            as InterpreterCatalog Function(dynamic);
        return fromJson({
          'enabled': true,
          'languages': [
            {'code': 'ru', 'name': 'Русский'}
          ],
        });
      });

      final result = await ds.catalog();

      expect(result.enabled, isTrue);
      expect(result.languages.single.code, 'ru');
    });

    test('maps a thrown ApiException to InterpreterException', () async {
      when(() => http.get<InterpreterCatalog>(
            '/interpreter/languages',
            fromJson: any(named: 'fromJson'),
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'interpreter_disabled',
        data: {'message': 'interpreter_disabled'},
      ));

      await expectLater(
        ds.catalog(),
        throwsA(isA<InterpreterException>().having(
          (e) => e.kind,
          'kind',
          InterpreterErrorKind.interpreterDisabled,
        )),
      );
    });
  });

  group('create', () {
    test('posts the chosen language and parses the hosted session', () async {
      when(() => http.post<HostedSession>(
            '/interpreter/sessions',
            data: {'lang': 'ru'},
            options: any(named: 'options'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((invocation) async {
        final fromJson = invocation.namedArguments[#fromJson] as HostedSession
            Function(dynamic);
        return fromJson({
          'sessionId': 's1',
          'code': 'ABC123',
          'expiresAt': '2026-11-01T12:05:00Z',
          'roomName': 'interp-s1',
          'token': 'tok',
          'livekitWsUrl': 'wss://lk/',
        });
      });

      final result = await ds.create('ru');

      expect(result.sessionId, 's1');
      expect(result.code, 'ABC123');
    });

    test(
        'flags the request as never-resend-after-timeout — a retried/'
        'failed-over create would open a second QR session', () async {
      when(() => http.post<HostedSession>(
            '/interpreter/sessions',
            data: {'lang': 'ru'},
            options: any(named: 'options'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((invocation) async {
        final fromJson = invocation.namedArguments[#fromJson] as HostedSession
            Function(dynamic);
        return fromJson({
          'sessionId': 's1',
          'code': 'ABC123',
          'expiresAt': '2026-11-01T12:05:00Z',
          'roomName': 'interp-s1',
          'token': 'tok',
          'livekitWsUrl': 'wss://lk/',
        });
      });

      await ds.create('ru');

      final captured = verify(() => http.post<HostedSession>(
            '/interpreter/sessions',
            data: {'lang': 'ru'},
            options: captureAny(named: 'options'),
            fromJson: any(named: 'fromJson'),
          )).captured;
      final options = captured.single as Options;
      expect(options.extra?[kNoResendAfterTimeout], isTrue);
    });

    test('maps same_language to InterpreterErrorKind.sameLanguage', () async {
      when(() => http.post<HostedSession>(
            '/interpreter/sessions',
            data: {'lang': 'ru'},
            options: any(named: 'options'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'same_language',
        data: {'message': 'same_language'},
      ));

      await expectLater(
        ds.create('ru'),
        throwsA(isA<InterpreterException>()
            .having((e) => e.kind, 'kind', InterpreterErrorKind.sameLanguage)),
      );
    });
  });

  group('newCode', () {
    test('posts to the session code endpoint and parses the response',
        () async {
      when(() => http.post<NewCode>(
            '/interpreter/sessions/s1/code',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson] as NewCode Function(dynamic);
        return fromJson({
          'code': 'XYZ789',
          'expiresAt': '2026-11-01T12:10:00Z',
        });
      });

      final result = await ds.newCode('s1');

      expect(result.code, 'XYZ789');
    });

    test('maps not_waiting on failure', () async {
      when(() => http.post<NewCode>(
            '/interpreter/sessions/s1/code',
            fromJson: any(named: 'fromJson'),
          )).thenThrow(const ApiException(
        statusCode: 409,
        message: 'not_waiting',
        data: {'message': 'not_waiting'},
      ));

      await expectLater(
        ds.newCode('s1'),
        throwsA(isA<InterpreterException>()
            .having((e) => e.kind, 'kind', InterpreterErrorKind.notWaiting)),
      );
    });
  });

  group('get', () {
    test('parses a session view', () async {
      when(() => http.get<SessionView>(
            '/interpreter/sessions/s1',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((invocation) async {
        final fromJson = invocation.namedArguments[#fromJson] as SessionView
            Function(dynamic);
        return fromJson({
          'status': 'active',
          'endReason': null,
          'partner': null,
          'directions': null,
          'startedAt': null,
          'spentPlanck': null,
        });
      });

      final result = await ds.get('s1');

      expect(result.status, InterpreterStatus.active);
    });

    test('maps session_not_found on failure', () async {
      when(() => http.get<SessionView>(
            '/interpreter/sessions/s1',
            fromJson: any(named: 'fromJson'),
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'session_not_found',
        data: {'message': 'session_not_found'},
      ));

      await expectLater(
        ds.get('s1'),
        throwsA(isA<InterpreterException>().having(
          (e) => e.kind,
          'kind',
          InterpreterErrorKind.sessionNotFound,
        )),
      );
    });
  });

  group('end', () {
    test('posts to the end endpoint', () async {
      when(() => http.post<dynamic>('/interpreter/sessions/s1/end'))
          .thenAnswer((_) async {});

      await ds.end('s1');

      verify(() => http.post<dynamic>('/interpreter/sessions/s1/end'))
          .called(1);
    });

    test('maps a failure to InterpreterException', () async {
      when(() => http.post<dynamic>('/interpreter/sessions/s1/end')).thenThrow(
          const ApiException(statusCode: 404, message: 'session_not_found'));

      await expectLater(ds.end('s1'), throwsA(isA<InterpreterException>()));
    });
  });

  group('join', () {
    Response<dynamic> responseWith(Map<String, dynamic> data) => Response(
          requestOptions: RequestOptions(path: '/interpreter/sessions/join'),
          statusCode: 200,
          data: data,
        );

    final joinJson = {
      'sessionId': 's1',
      'roomName': 'interp-s1',
      'token': 'tok',
      'livekitWsUrl': 'wss://lk/',
      'partner': {'firstName': 'Anna', 'avatarUrl': null, 'lang': 'de'},
      'directions': {'toMe': 'simultaneous', 'fromMe': 'phrase'},
    };

    test(
        'goes through client.dio with a receiveTimeout of at least 40s and the right body',
        () async {
      when(() => http.dio).thenReturn(dio);
      when(() => dio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => responseWith(joinJson));

      final result = await ds.join('ABC123', 'en');

      expect(result.sessionId, 's1');
      expect(result.partner.firstName, 'Anna');
      expect(result.directions.fromMe, InterpreterEngine.phrase);

      final captured = verify(() => dio.post(
            '/interpreter/sessions/join',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          )).captured;
      final body = captured[0] as Map;
      final options = captured[1] as Options;
      expect(body, {'code': 'ABC123', 'lang': 'en'});
      expect(options.receiveTimeout, isNotNull);
      expect(options.receiveTimeout!.inSeconds, greaterThanOrEqualTo(40));
      // A retried/failed-over join could consume the single-use code twice
      // and double-open the host's billing session.
      expect(options.extra?[kNoResendAfterTimeout], isTrue);
    });

    test('maps a DioException with a backend code to InterpreterException',
        () async {
      when(() => http.dio).thenReturn(dio);
      when(() => dio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/interpreter/sessions/join'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/interpreter/sessions/join'),
          statusCode: 410,
          data: {'statusCode': 410, 'message': 'code_expired'},
        ),
      ));

      await expectLater(
        ds.join('ABC123', 'en'),
        throwsA(isA<InterpreterException>().having(
          (e) => e.kind,
          'kind',
          InterpreterErrorKind.codeExpired,
        )),
      );
    });

    test('maps a connection-level DioException to network', () async {
      when(() => http.dio).thenReturn(dio);
      when(() => dio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/interpreter/sessions/join'),
        type: DioExceptionType.connectionError,
      ));

      await expectLater(
        ds.join('ABC123', 'en'),
        throwsA(isA<InterpreterException>()
            .having((e) => e.kind, 'kind', InterpreterErrorKind.network)),
      );
    });
  });
}
