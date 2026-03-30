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
  late CallStateService svc;

  setUp(() async {
    svc = CallStateService.instance;
    // Reset state by ending all calls
    await svc.endCall();
  });

  // ── isInCall ──────────────────────────────────────────────────────────────

  group('isInCall', () {
    test('returns false when no lines', () {
      expect(svc.isInCall, isFalse);
    });

    test('returns true when room is set', () {
      svc.setRoom(MockRoom(), 'room-1', null);
      expect(svc.isInCall, isTrue);
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
    test('clears active line', () {
      svc.setRoom(MockRoom(), 'room-xyz', 'conv-1');
      svc.notifyEnded();

      expect(svc.room, isNull);
      expect(svc.roomName, isNull);
      expect(svc.isInCall, isFalse);
    });

    test('emits false on stateStream when last line ended', () async {
      svc.setRoom(MockRoom(), 'room-1', null);
      final events = <bool>[];
      final sub = svc.stateStream.listen(events.add);

      svc.notifyEnded();
      await Future.delayed(Duration.zero);

      expect(events, [false]);
      await sub.cancel();
    });

    test('switches to next line if multiple', () {
      svc.setRoom(MockRoom(), 'room-1', null);
      svc.setRoom(MockRoom(), 'room-2', null);

      svc.notifyEnded(); // ends room-2 (active)

      expect(svc.isInCall, isTrue);
      expect(svc.roomName, 'room-1');
    });
  });

  // ── endCall ───────────────────────────────────────────────────────────────

  group('endCall', () {
    test('clears all lines and emits false', () async {
      final room = MockRoom();
      when(() => room.disconnect()).thenAnswer((_) async {});
      svc.setRoom(room, 'room-abc', null);

      final events = <bool>[];
      final sub = svc.stateStream.listen(events.add);

      await svc.endCall();
      await Future.delayed(Duration.zero);

      expect(svc.room, isNull);
      expect(svc.roomName, isNull);
      expect(svc.lineCount, 0);
      expect(events, contains(false));
      await sub.cancel();
    });

    test('calls disconnect on all rooms', () async {
      final room1 = MockRoom();
      final room2 = MockRoom();
      when(() => room1.disconnect()).thenAnswer((_) async {});
      when(() => room2.disconnect()).thenAnswer((_) async {});
      svc.setRoom(room1, 'room-1', null);
      svc.setRoom(room2, 'room-2', null);

      await svc.endCall();

      verify(() => room1.disconnect()).called(1);
      verify(() => room2.disconnect()).called(1);
    });

    test('does not throw when no lines', () async {
      await expectLater(svc.endCall(), completes);
    });
  });

  // ── Multi-line ──────────────────────────────────────────────────────────

  group('Multi-line', () {
    test('can hold multiple lines', () {
      svc.setRoom(MockRoom(), 'room-1', null);
      svc.setRoom(MockRoom(), 'room-2', null);
      svc.setRoom(MockRoom(), 'room-3', null);

      expect(svc.lineCount, 3);
      expect(svc.roomName, 'room-3'); // last set is active
    });

    test('endLine removes specific line', () async {
      final room1 = MockRoom();
      final room2 = MockRoom();
      when(() => room1.disconnect()).thenAnswer((_) async {});
      when(() => room2.disconnect()).thenAnswer((_) async {});
      svc.setRoom(room1, 'room-1', null);
      svc.setRoom(room2, 'room-2', null);

      await svc.endLine('room-1');

      expect(svc.lineCount, 1);
      expect(svc.roomName, 'room-2');
      verify(() => room1.disconnect()).called(1);
    });

    test('endLine switches to remaining line when active ended', () async {
      final room1 = MockRoom();
      final room2 = MockRoom();
      when(() => room1.disconnect()).thenAnswer((_) async {});
      when(() => room2.disconnect()).thenAnswer((_) async {});
      svc.setRoom(room1, 'room-1', null);
      svc.setRoom(room2, 'room-2', null);

      await svc.endLine('room-2'); // end active line

      expect(svc.roomName, 'room-1');
      expect(svc.lineCount, 1);
    });

    test('allLines returns all lines', () {
      svc.setRoom(MockRoom(), 'room-1', 'conv-1');
      svc.setRoom(MockRoom(), 'room-2', 'conv-2');

      final lines = svc.allLines;
      expect(lines.length, 2);
      expect(lines.map((l) => l.roomName).toSet(), {'room-1', 'room-2'});
    });
  });

  // ── stateStream ───────────────────────────────────────────────────────────

  group('stateStream', () {
    test('is a broadcast stream', () async {
      final events1 = <bool>[];
      final events2 = <bool>[];
      final sub1 = svc.stateStream.listen(events1.add);
      final sub2 = svc.stateStream.listen(events2.add);

      svc.setRoom(MockRoom(), 'room-1', null);
      await Future.delayed(Duration.zero);

      expect(events1, [true]);
      expect(events2, [true]);
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

      svc.setRoom(MockRoom(), 'room-1', null);
      expect(await svc.waitForBackgroundConnect(), isTrue);
    });
  });
}
