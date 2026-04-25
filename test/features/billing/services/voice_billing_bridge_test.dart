import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/features/billing/data/services/billing_event_bus.dart';
import 'package:taler_id_mobile/features/billing/data/services/voice_billing_bridge.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dio;
  late BillingEventBus bus;
  late VoiceBillingBridge bridge;

  setUpAll(() {
    // `data` is `dynamic` in DioClient.post — register a fallback matcher.
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    dio = MockDioClient();
    bus = BillingEventBus();
    // 60ms heartbeat so tests don't hang; we only need to prove the timer ticks.
    bridge = VoiceBillingBridge(
      dio: dio,
      eventBus: bus,
      heartbeatInterval: const Duration(milliseconds: 60),
    );
  });

  tearDown(() async {
    await bridge.dispose();
    await bus.dispose();
  });

  // ── start ───────────────────────────────────────────────────────────────

  group('start', () {
    test('captures billingSessionId and clientSecret from POST /voice/session',
        () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/voice/session',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {
            'clientSecret': 'sk_ephemeral_xyz',
            'billingSessionId': 'sess-123',
          });

      final handle = await bridge.start();

      expect(handle.billingSessionId, 'sess-123');
      expect(handle.clientSecret, 'sk_ephemeral_xyz');
      expect(bridge.sessionId, 'sess-123');
    });

    test(
        'returns empty sessionId when backend omits billingSessionId '
        '(backward compat with pre-billing backend)', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/voice/session',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer(
              (_) async => {'clientSecret': 'sk_ephemeral_xyz'});

      final handle = await bridge.start();

      expect(handle.billingSessionId, '');
      expect(handle.clientSecret, 'sk_ephemeral_xyz');
      expect(bridge.sessionId, isNull);
    });

    test('propagates 402 InsufficientFunds so caller can abort connect',
        () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/voice/session',
            fromJson: any(named: 'fromJson'),
          )).thenThrow(const ApiException(
              statusCode: 402, message: 'Insufficient funds'));

      expect(bridge.start(), throwsA(isA<ApiException>()));
    });
  });

  // ── heartbeat ───────────────────────────────────────────────────────────

  group('heartbeat', () {
    test('fires POST /metering/heartbeat every interval with sessionId',
        () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/voice/session',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {
            'clientSecret': 'sk_x',
            'billingSessionId': 'sess-42',
          });
      when(() => dio.post<dynamic>(
            '/metering/heartbeat',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {'ok': true});

      await bridge.start();
      // Wait for ~3 heartbeat ticks (interval = 60ms).
      await Future<void>.delayed(const Duration(milliseconds: 210));

      final captured = verify(() => dio.post<dynamic>(
            '/metering/heartbeat',
            data: captureAny(named: 'data'),
          )).captured;
      expect(captured, isNotEmpty);
      // Every captured body should reference our sessionId.
      for (final body in captured) {
        expect((body as Map<String, dynamic>)['sessionId'], 'sess-42');
      }
    });

    test('stops beating on 404 without crashing', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/voice/session',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {
            'clientSecret': 'sk_x',
            'billingSessionId': 'sess-stale',
          });
      var heartbeatCallCount = 0;
      when(() => dio.post<dynamic>(
            '/metering/heartbeat',
            data: any(named: 'data'),
          )).thenAnswer((_) async {
        heartbeatCallCount++;
        throw const ApiException(statusCode: 404, message: 'No session');
      });

      await bridge.start();
      // Give the timer time to tick once and cancel itself.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final beforeCount = heartbeatCallCount;
      expect(beforeCount, greaterThanOrEqualTo(1));

      // Wait longer — should NOT produce more ticks since the first 404
      // cancelled the timer.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(heartbeatCallCount, beforeCount,
          reason: 'timer must be cancelled after first 404');
    });
  });

  // ── stop ────────────────────────────────────────────────────────────────

  group('stop', () {
    test('POSTs /voice/session/:id/close with durationSec', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/voice/session',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {
            'clientSecret': 'sk_x',
            'billingSessionId': 'sess-close',
          });
      when(() => dio.post<dynamic>(
            '/metering/heartbeat',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {});
      when(() => dio.post<dynamic>(
            any(that: startsWith('/voice/session/')),
            data: any(named: 'data'),
          )).thenAnswer((_) async => {'ok': true});

      await bridge.start();
      await bridge.stop(durationSec: 42);

      verify(() => dio.post<dynamic>(
            '/voice/session/sess-close/close',
            data: {'durationSec': 42},
          )).called(1);
      expect(bridge.sessionId, isNull);
    });

    test('swallows close errors so the UI flow never breaks on hangup',
        () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/voice/session',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {
            'clientSecret': 'sk_x',
            'billingSessionId': 'sess-err',
          });
      when(() => dio.post<dynamic>(
            '/metering/heartbeat',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {});
      when(() => dio.post<dynamic>(
            any(that: startsWith('/voice/session/')),
            data: any(named: 'data'),
          )).thenThrow(
              const ApiException(statusCode: 500, message: 'boom'));

      await bridge.start();
      await expectLater(bridge.stop(durationSec: 10), completes);
      expect(bridge.sessionId, isNull);
    });

    test('double-stop is a no-op', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/voice/session',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {
            'clientSecret': 'sk_x',
            'billingSessionId': 'sess-double',
          });
      when(() => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
          )).thenAnswer((_) async => {});

      await bridge.start();
      await bridge.stop(durationSec: 1);
      await bridge.stop(durationSec: 2);

      verify(() => dio.post<dynamic>(
            '/voice/session/sess-double/close',
            data: any(named: 'data'),
          )).called(1);
    });
  });

  // ── terminated events ──────────────────────────────────────────────────

  group('onTerminated', () {
    test('emits only events matching the current sessionId', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/voice/session',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {
            'clientSecret': 'sk_x',
            'billingSessionId': 'sess-mine',
          });
      when(() => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
          )).thenAnswer((_) async => {});

      await bridge.start();

      final received = <AiSessionTerminatedEvent>[];
      final sub = bridge.onTerminated.listen(received.add);

      bus.pushSessionTerminated(AiSessionTerminatedEvent(
        sessionId: 'sess-other',
        reason: 'no_funds',
        featureKey: 'ai.voice_assistant',
      ));
      bus.pushSessionTerminated(AiSessionTerminatedEvent(
        sessionId: 'sess-mine',
        reason: 'no_funds',
        featureKey: 'ai.voice_assistant',
      ));

      // Let the stream drain.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(received, hasLength(1));
      expect(received.single.sessionId, 'sess-mine');
      expect(received.single.reason, 'no_funds');

      await sub.cancel();
    });
  });
}
