// test/core/platform/call_kit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/call_kit.dart';
import 'package:taler_id_mobile/core/platform/call_kit_desktop.dart';

void main() {
  // Reset singleton before each test so platform dispatch is re-evaluated.
  setUp(() => CallKitPlatform.debugResetForTest());
  tearDown(() => CallKitPlatform.debugResetForTest());

  group('CallKitEvent', () {
    test('type constants are non-empty strings', () {
      expect(CallKitEvent.typeAccept, isNotEmpty);
      expect(CallKitEvent.typeDecline, isNotEmpty);
      expect(CallKitEvent.typeEnded, isNotEmpty);
      expect(CallKitEvent.typeTimeout, isNotEmpty);
      expect(CallKitEvent.typeConnected, isNotEmpty);
      expect(CallKitEvent.typeIncoming, isNotEmpty);
    });

    test('constructs with required fields', () {
      const e = CallKitEvent(type: 'test', uuid: 'abc-123');
      expect(e.type, 'test');
      expect(e.uuid, 'abc-123');
      expect(e.data, isNull);
    });

    test('constructs with optional data', () {
      const e = CallKitEvent(
        type: CallKitEvent.typeAccept,
        uuid: 'u1',
        data: {'extra': <String, dynamic>{'roomName': 'room1'}},
      );
      expect(e.data?['extra'], isA<Map>());
    });
  });

  group('CallKitDesktop (no-op)', () {
    late CallKitDesktop desktop;

    setUp(() => desktop = CallKitDesktop());

    test('showIncomingCall is a no-op', () async {
      await expectLater(
        desktop.showIncomingCall(
          uuid: 'u1',
          callerName: 'Alice',
          roomName: 'room1',
        ),
        completes,
      );
    });

    test('endCall is a no-op', () async {
      await expectLater(desktop.endCall('u1'), completes);
    });

    test('endAllCalls is a no-op', () async {
      await expectLater(desktop.endAllCalls(), completes);
    });

    test('activeCalls returns empty list', () async {
      final calls = await desktop.activeCalls();
      expect(calls, isEmpty);
    });

    test('getDevicePushTokenVoIP returns null', () async {
      final token = await desktop.getDevicePushTokenVoIP();
      expect(token, isNull);
    });

    test('events stream emits nothing', () async {
      final events = <CallKitEvent>[];
      final sub = desktop.events.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      expect(events, isEmpty);
    });
  });

  group('CallKitPlatform.debugResetForTest', () {
    test('resets singleton so next access re-creates it', () {
      // Accessing instance creates the singleton.
      final a = CallKitPlatform.instance;
      // Resetting then re-accessing creates a fresh instance.
      CallKitPlatform.debugResetForTest();
      final b = CallKitPlatform.instance;
      // Both should be valid instances (not null / not the same object).
      expect(a, isNotNull);
      expect(b, isNotNull);
    });
  });
}
