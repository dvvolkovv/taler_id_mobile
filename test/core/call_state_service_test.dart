import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/services/call_state_service.dart';

class MockRoom extends Mock implements lk.Room {
  @override
  lk.ConnectionState get connectionState => lk.ConnectionState.connected;
}

class DisconnectedRoom extends Mock implements lk.Room {
  @override
  lk.ConnectionState get connectionState => lk.ConnectionState.disconnected;
}

void main() {
  // CallStateService is a singleton — use a fresh instance per test
  // by resetting its state between tests.
  late CallStateService svc;

  setUp(() {
    svc = CallStateService.instance;
    // Reset state
    svc.room = null;
    svc.roomName = null;
    svc.conversationId = null;
    svc.e2eeKey = null;
  });

  // ── isInCall ──────────────────────────────────────────────────────────────

  group('isInCall', () {
    test('returns false when room is null', () {
      expect(svc.isInCall, isFalse);
    });

    test('returns true when room is connected', () {
      svc.room = MockRoom();
      expect(svc.isInCall, isTrue);
    });

    test('returns false when room is disconnected', () {
      svc.room = DisconnectedRoom();
      expect(svc.isInCall, isFalse);
    });
  });

  // ── setRoom ───────────────────────────────────────────────────────────────

  group('setRoom', () {
    test('sets all fields correctly', () {
      final room = MockRoom();
      svc.setRoom(room, 'room-xyz', 'conv-1', e2eeKeyValue: 'secret');

      expect(svc.room, same(room));
      expect(svc.roomName, 'room-xyz');
      expect(svc.conversationId, 'conv-1');
      expect(svc.e2eeKey, 'secret');
    });

    test('sets fields without e2ee key', () {
      final room = MockRoom();
      svc.setRoom(room, 'room-abc', null);

      expect(svc.room, same(room));
      expect(svc.roomName, 'room-abc');
      expect(svc.conversationId, isNull);
      expect(svc.e2eeKey, isNull);
    });

    test('emits true on stateStream when room set', () async {
      final room = MockRoom();
      final events = <bool>[];
      final sub = svc.stateStream.listen(events.add);

      svc.setRoom(room, 'room-1', null);
      await Future.delayed(Duration.zero);

      expect(events, [true]);
      await sub.cancel();
    });
  });

  // ── notifyEnded ───────────────────────────────────────────────────────────

  group('notifyEnded', () {
    test('clears all fields', () {
      svc.room = MockRoom();
      svc.roomName = 'room-xyz';
      svc.conversationId = 'conv-1';
      svc.e2eeKey = 'secret';

      svc.notifyEnded();

      expect(svc.room, isNull);
      expect(svc.roomName, isNull);
      expect(svc.conversationId, isNull);
      expect(svc.e2eeKey, isNull);
      expect(svc.isInCall, isFalse);
    });

    test('emits false on stateStream', () async {
      svc.room = MockRoom();
      final events = <bool>[];
      final sub = svc.stateStream.listen(events.add);

      svc.notifyEnded();
      await Future.delayed(Duration.zero);

      expect(events, [false]);
      await sub.cancel();
    });

    test('isInCall is false after notifyEnded', () {
      svc.room = MockRoom();
      expect(svc.isInCall, isTrue);

      svc.notifyEnded();
      expect(svc.isInCall, isFalse);
    });
  });

  // ── endCall ───────────────────────────────────────────────────────────────

  group('endCall', () {
    test('clears room and emits false', () async {
      final room = MockRoom();
      when(() => room.disconnect()).thenAnswer((_) async {});
      svc.room = room;
      svc.roomName = 'room-abc';

      final events = <bool>[];
      final sub = svc.stateStream.listen(events.add);

      await svc.endCall();
      await Future.delayed(Duration.zero);

      expect(svc.room, isNull);
      expect(svc.roomName, isNull);
      expect(events, contains(false));
      await sub.cancel();
    });

    test('calls disconnect on the room', () async {
      final room = MockRoom();
      when(() => room.disconnect()).thenAnswer((_) async {});
      svc.room = room;

      await svc.endCall();

      verify(() => room.disconnect()).called(1);
    });

    test('does not throw when room is null', () async {
      svc.room = null;
      await expectLater(svc.endCall(), completes);
    });

    test('silently handles disconnect exception', () async {
      final room = MockRoom();
      when(() => room.disconnect()).thenThrow(Exception('WebRTC error'));
      svc.room = room;

      await expectLater(svc.endCall(), completes);
      expect(svc.room, isNull);
    });
  });

  // ── stateStream ───────────────────────────────────────────────────────────

  group('stateStream', () {
    test('is a broadcast stream (multiple listeners ok)', () async {
      final events1 = <bool>[];
      final events2 = <bool>[];
      final sub1 = svc.stateStream.listen(events1.add);
      final sub2 = svc.stateStream.listen(events2.add);

      svc.notifyEnded();
      await Future.delayed(Duration.zero);

      expect(events1, [false]);
      expect(events2, [false]);
      await sub1.cancel();
      await sub2.cancel();
    });

    test('emits true then false across call lifecycle', () async {
      final room = MockRoom();
      when(() => room.disconnect()).thenAnswer((_) async {});
      final events = <bool>[];
      final sub = svc.stateStream.listen(events.add);

      svc.setRoom(room, 'room-1', null);
      await Future.delayed(Duration.zero);
      await svc.endCall();
      await Future.delayed(Duration.zero);

      expect(events, [true, false]);
      await sub.cancel();
    });
  });

  // ── isBackgroundConnecting ─────────────────────────────────────────────────

  group('isBackgroundConnecting', () {
    test('is false by default', () {
      expect(svc.isBackgroundConnecting, isFalse);
    });
  });

  // ── waitForBackgroundConnect ──────────────────────────────────────────────

  group('waitForBackgroundConnect', () {
    test('returns current isInCall when not connecting', () async {
      expect(await svc.waitForBackgroundConnect(), isFalse);

      svc.room = MockRoom();
      expect(await svc.waitForBackgroundConnect(), isTrue);
    });
  });
}
