import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/services/call_state_service.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockRoom extends Mock implements lk.Room {
  @override
  lk.ConnectionState get connectionState => lk.ConnectionState.connected;
}

class MockLocalParticipant extends Mock implements lk.LocalParticipant {}

class MockDioClient extends Mock implements DioClient {}

/// Build a MockRoom with a stubbed LocalParticipant.
MockRoom _makeRoom({bool micEnabled = true}) {
  final room = MockRoom();
  final participant = MockLocalParticipant();
  when(() => room.localParticipant).thenReturn(participant);
  when(() => participant.isMicrophoneEnabled()).thenReturn(micEnabled);
  when(() => participant.setMicrophoneEnabled(any())).thenAnswer((_) async => null);
  when(() => participant.setCameraEnabled(any())).thenAnswer((_) async => null);
  when(() => room.disconnect()).thenAnswer((_) async {});
  return room;
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late CallStateService svc;

  setUp(() async {
    svc = CallStateService.instance;
    await svc.endCall();
  });

  // ── Initial state ─────────────────────────────────────────────────────────

  group('initial state', () {
    test('no active call', () {
      expect(svc.isInCall, isFalse);
      expect(svc.lineCount, 0);
      expect(svc.canAddLine, isTrue);
      expect(svc.activeLine, isNull);
      expect(svc.allLines, isEmpty);
      expect(svc.isBackgroundConnecting, isFalse);
    });
  });

  // ── setRoom ───────────────────────────────────────────────────────────────

  group('setRoom', () {
    test('sets all fields correctly', () {
      final room = _makeRoom();
      svc.setRoom(room, 'room-xyz', 'conv-1', e2eeKeyValue: 'secret', lkToken: 'lk-secret');

      expect(svc.room, same(room));
      expect(svc.roomName, 'room-xyz');
      expect(svc.conversationId, 'conv-1');
      expect(svc.e2eeKey, 'secret');
      expect(svc.lkToken, 'lk-secret');
    });

    test('lkToken is null when not passed — distinct from a real token', () {
      // Guards against a copy/paste mixup with e2eeKeyValue silently landing
      // in the wrong field: both are optional secrets threaded through the
      // same call.
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1', e2eeKeyValue: 'secret');

      expect(svc.lkToken, isNull);
      expect(svc.e2eeKey, 'secret');
    });

    test('sets connectedAt', () {
      final before = DateTime.now();
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1');
      final after = DateTime.now();

      final t = svc.activeLine!.connectedAt!;
      expect(t.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(t.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('stores calleeName and calleeAvatar', () {
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1',
          calleeName: 'Alice', calleeAvatar: 'https://img/alice.png');

      expect(svc.activeLine?.calleeName, 'Alice');
      expect(svc.activeLine?.calleeAvatar, 'https://img/alice.png');
    });

    test('second room does not remove first', () {
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1');
      svc.setRoom(_makeRoom(), 'room-2', 'conv-2');

      expect(svc.lineCount, 2);
      expect(svc.roomName, 'room-2');
      expect(svc.allLines.map((l) => l.roomName), containsAll(['room-1', 'room-2']));
    });

    test('emits on stateStream', () async {
      final events = <bool>[];
      final sub = svc.stateStream.listen(events.add);
      svc.setRoom(_makeRoom(), 'room-1', null);
      await Future.delayed(Duration.zero);
      expect(events, contains(true));
      await sub.cancel();
    });

    test('emits roomName on activeRoomStream', () async {
      final emitted = <String?>[];
      final sub = svc.activeRoomStream.listen(emitted.add);
      svc.setRoom(_makeRoom(), 'room-1', null);
      await Future.delayed(Duration.zero);
      expect(emitted, contains('room-1'));
      await sub.cancel();
    });
  });

  // ── canAddLine ────────────────────────────────────────────────────────────

  group('canAddLine', () {
    test('true with 0 lines', () => expect(svc.canAddLine, isTrue));

    test('true with maxLines-1 lines', () {
      for (int i = 0; i < CallStateService.maxLines - 1; i++) {
        svc.setRoom(_makeRoom(), 'room-$i', null);
      }
      expect(svc.canAddLine, isTrue);
    });

    test('false at maxLines', () {
      for (int i = 0; i < CallStateService.maxLines; i++) {
        svc.setRoom(_makeRoom(), 'room-$i', null);
      }
      expect(svc.canAddLine, isFalse);
    });
  });

  // ── holdAndSwitch ─────────────────────────────────────────────────────────

  group('holdAndSwitch', () {
    test('puts active on hold and switches to target', () async {
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1');
      svc.setRoom(_makeRoom(), 'room-2', 'conv-2');
      // room-2 is active
      await svc.holdAndSwitch('room-1');

      expect(svc.activeLine?.roomName, 'room-1');
      expect(svc.activeLine?.isOnHold, isFalse);
      final held = svc.allLines.firstWhere((l) => l.roomName == 'room-2');
      expect(held.isOnHold, isTrue);
    });

    test('saves wasMuted before putting line on hold', () async {
      svc.setRoom(_makeRoom(micEnabled: true), 'room-1', 'conv-1');
      svc.setRoom(_makeRoom(micEnabled: false), 'room-2', 'conv-2');
      // room-2 is active with mic OFF

      await svc.holdAndSwitch('room-1');

      // room-2 was held — wasMuted = true (mic was disabled)
      final held = svc.allLines.firstWhere((l) => l.roomName == 'room-2');
      expect(held.wasMuted, isTrue);
    });

    test('saves wasMuted=false when mic was on', () async {
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1');
      svc.setRoom(_makeRoom(micEnabled: true), 'room-2', 'conv-2');
      // room-2 active with mic ON

      await svc.holdAndSwitch('room-1');

      final held = svc.allLines.firstWhere((l) => l.roomName == 'room-2');
      expect(held.wasMuted, isFalse);
    });

    test('restores mic on target using wasMuted', () async {
      // room-1 was on hold with mic off (wasMuted=true)
      final room1 = _makeRoom(micEnabled: false);
      svc.setRoom(room1, 'room-1', 'conv-1');
      final line1 = svc.activeLine!;
      line1.isOnHold = true;
      line1.wasMuted = true; // simulate: was muted before hold

      svc.setRoom(_makeRoom(), 'room-2', 'conv-2');
      await svc.holdAndSwitch('room-1');

      final p1 = room1.localParticipant as MockLocalParticipant;
      // wasMuted=true → setMicrophoneEnabled(false)
      verify(() => p1.setMicrophoneEnabled(false)).called(greaterThan(0));
    });

    test('noop when switching to already active line', () async {
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1');
      await svc.holdAndSwitch('room-1');

      expect(svc.activeLine?.roomName, 'room-1');
      expect(svc.activeLine?.isOnHold, isFalse);
    });

    test('hasHeldLines is true after switching', () async {
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1');
      svc.setRoom(_makeRoom(), 'room-2', 'conv-2');
      expect(svc.hasHeldLines, isFalse);

      await svc.holdAndSwitch('room-1');
      expect(svc.hasHeldLines, isTrue);
    });

    test('emits new active roomName on activeRoomStream', () async {
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1');
      svc.setRoom(_makeRoom(), 'room-2', 'conv-2');

      final emitted = <String?>[];
      final sub = svc.activeRoomStream.listen(emitted.add);
      await svc.holdAndSwitch('room-1');
      await Future.delayed(Duration.zero);

      expect(emitted, contains('room-1'));
      await sub.cancel();
    });

    test('mutes mic on the held room', () async {
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1');
      final room2 = _makeRoom();
      svc.setRoom(room2, 'room-2', 'conv-2');

      await svc.holdAndSwitch('room-1');

      final p2 = room2.localParticipant as MockLocalParticipant;
      verify(() => p2.setMicrophoneEnabled(false)).called(greaterThan(0));
    });
  });

  // ── endLine ───────────────────────────────────────────────────────────────

  group('endLine', () {
    test('removes specified line', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);
      svc.setRoom(_makeRoom(), 'room-2', null);

      await svc.endLine('room-1');

      expect(svc.lineCount, 1);
      expect(svc.allLines.map((l) => l.roomName), isNot(contains('room-1')));
    });

    test('switches to next line when ending active', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);
      svc.setRoom(_makeRoom(), 'room-2', null);
      // room-2 is active

      await svc.endLine('room-2');

      expect(svc.roomName, 'room-1');
      expect(svc.isInCall, isTrue);
    });

    test('isInCall false when last line ends', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);
      await svc.endLine('room-1');

      expect(svc.isInCall, isFalse);
      expect(svc.activeLine, isNull);
    });

    test('emits null on activeRoomStream when last line ends', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);

      final emitted = <String?>[];
      final sub = svc.activeRoomStream.listen(emitted.add);
      await svc.endLine('room-1');
      await Future.delayed(Duration.zero);

      expect(emitted, contains(null));
      await sub.cancel();
    });

    test('emits next roomName on activeRoomStream when switching', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);
      svc.setRoom(_makeRoom(), 'room-2', null);

      final emitted = <String?>[];
      final sub = svc.activeRoomStream.listen(emitted.add);
      await svc.endLine('room-2'); // end active
      await Future.delayed(Duration.zero);

      expect(emitted, contains('room-1'));
      await sub.cancel();
    });

    test('calls disconnect on the ended room', () async {
      final room = _makeRoom();
      svc.setRoom(room, 'room-1', null);
      await svc.endLine('room-1');

      verify(() => room.disconnect()).called(1);
    });

    test('non-active line can be ended without switching', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);
      svc.setRoom(_makeRoom(), 'room-2', null);
      // room-2 is active

      await svc.endLine('room-1'); // end the held line

      expect(svc.activeLine?.roomName, 'room-2');
      expect(svc.lineCount, 1);
    });

    test('restores wasMuted on next line after ending active', () async {
      final room1 = _makeRoom(micEnabled: false);
      svc.setRoom(room1, 'room-1', null);
      // Mark room-1 as held with mic off
      svc.allLines.first.isOnHold = true;
      svc.allLines.first.wasMuted = true;

      svc.setRoom(_makeRoom(), 'room-2', null);
      await svc.endLine('room-2'); // end active

      // room-1 becomes active — wasMuted=true → setMicrophoneEnabled(false)
      final p1 = room1.localParticipant as MockLocalParticipant;
      verify(() => p1.setMicrophoneEnabled(false)).called(greaterThan(0));
    });
  });

  // ── endCall ───────────────────────────────────────────────────────────────

  group('endCall', () {
    test('clears all lines', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);
      svc.setRoom(_makeRoom(), 'room-2', null);

      await svc.endCall();

      expect(svc.isInCall, isFalse);
      expect(svc.lineCount, 0);
      expect(svc.activeLine, isNull);
    });

    test('disconnects all rooms', () async {
      final room1 = _makeRoom();
      final room2 = _makeRoom();
      svc.setRoom(room1, 'room-1', null);
      svc.setRoom(room2, 'room-2', null);

      await svc.endCall();

      verify(() => room1.disconnect()).called(1);
      verify(() => room2.disconnect()).called(1);
    });

    test('emits false on stateStream', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);

      final events = <bool>[];
      final sub = svc.stateStream.listen(events.add);
      await svc.endCall();
      await Future.delayed(Duration.zero);

      expect(events, contains(false));
      await sub.cancel();
    });

    test('emits null on activeRoomStream', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);

      final emitted = <String?>[];
      final sub = svc.activeRoomStream.listen(emitted.add);
      await svc.endCall();
      await Future.delayed(Duration.zero);

      expect(emitted, contains(null));
      await sub.cancel();
    });

    test('does not throw when empty', () async {
      await expectLater(svc.endCall(), completes);
    });
  });

  // ── notifyEnded ───────────────────────────────────────────────────────────

  group('notifyEnded', () {
    test('clears active line', () {
      svc.setRoom(_makeRoom(), 'room-1', null);
      svc.notifyEnded();

      expect(svc.room, isNull);
      expect(svc.isInCall, isFalse);
    });

    test('switches to next line if available', () {
      svc.setRoom(_makeRoom(), 'room-1', null);
      svc.setRoom(_makeRoom(), 'room-2', null);

      svc.notifyEnded(); // ends room-2 (active)

      expect(svc.isInCall, isTrue);
      expect(svc.roomName, 'room-1');
    });

    test('emits false when last line ended', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);
      final events = <bool>[];
      final sub = svc.stateStream.listen(events.add);

      svc.notifyEnded();
      await Future.delayed(Duration.zero);

      expect(events, contains(false));
      await sub.cancel();
    });
  });

  // ── stateStream ───────────────────────────────────────────────────────────

  group('stateStream', () {
    test('broadcast — multiple listeners', () async {
      final ev1 = <bool>[], ev2 = <bool>[];
      final s1 = svc.stateStream.listen(ev1.add);
      final s2 = svc.stateStream.listen(ev2.add);

      svc.setRoom(_makeRoom(), 'room-1', null);
      await Future.delayed(Duration.zero);

      expect(ev1, contains(true));
      expect(ev2, contains(true));
      await s1.cancel();
      await s2.cancel();
    });

    test('new subscriber receives current state immediately', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);
      final first = await svc.stateStream.first;
      expect(first, isTrue);
    });

    test('full lifecycle: true then false', () async {
      final events = <bool>[];
      final sub = svc.stateStream.listen(events.add);

      svc.setRoom(_makeRoom(), 'room-1', null);
      await Future.delayed(Duration.zero);
      await svc.endCall();
      await Future.delayed(Duration.zero);

      expect(events, containsAllInOrder([true, false]));
      await sub.cancel();
    });
  });

  // ── activeRoomStream ──────────────────────────────────────────────────────

  group('activeRoomStream', () {
    test('emits when setRoom called', () async {
      final emitted = <String?>[];
      final sub = svc.activeRoomStream.listen(emitted.add);
      svc.setRoom(_makeRoom(), 'room-A', null);
      await Future.delayed(Duration.zero);
      expect(emitted, contains('room-A'));
      await sub.cancel();
    });

    test('emits new room after holdAndSwitch', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);
      svc.setRoom(_makeRoom(), 'room-2', null);

      final emitted = <String?>[];
      final sub = svc.activeRoomStream.listen(emitted.add);
      await svc.holdAndSwitch('room-1');
      await Future.delayed(Duration.zero);

      expect(emitted, contains('room-1'));
      await sub.cancel();
    });

    test('emits null after endCall', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);

      final emitted = <String?>[];
      final sub = svc.activeRoomStream.listen(emitted.add);
      await svc.endCall();
      await Future.delayed(Duration.zero);

      expect(emitted, contains(null));
      await sub.cancel();
    });

    test('emits null after last endLine', () async {
      svc.setRoom(_makeRoom(), 'room-1', null);

      final emitted = <String?>[];
      final sub = svc.activeRoomStream.listen(emitted.add);
      await svc.endLine('room-1');
      await Future.delayed(Duration.zero);

      expect(emitted, contains(null));
      await sub.cancel();
    });
  });

  // ── waitForBackgroundConnect ──────────────────────────────────────────────

  group('waitForBackgroundConnect', () {
    test('returns isInCall when not connecting', () async {
      expect(await svc.waitForBackgroundConnect(), isFalse);

      svc.setRoom(_makeRoom(), 'room-1', null);
      expect(await svc.waitForBackgroundConnect(), isTrue);
    });
  });

  // ── System calls (iOS CallKit) ───────────────────────────────────────────

  group('system hold', () {
    late MockRoom room;
    late MockLocalParticipant mic;

    void line({required bool micOn}) {
      room = _makeRoom(micEnabled: micOn);
      mic = room.localParticipant! as MockLocalParticipant;
      svc.setRoom(room, 'room-1', 'conv-1');
    }

    test('hold turns an open mic off, resume turns it back on', () async {
      line(micOn: true);
      await svc.applySystemHold('room-1');
      verify(() => mic.setMicrophoneEnabled(false)).called(1);
      expect(svc.activeLine!.heldBySystem, isTrue);
      await svc.applySystemResume('room-1');
      verify(() => mic.setMicrophoneEnabled(true)).called(1);
      expect(svc.activeLine!.heldBySystem, isFalse);
    });

    test('a mic muted before the hold stays muted after it', () async {
      line(micOn: false);
      await svc.applySystemHold('room-1');
      await svc.applySystemResume('room-1');
      verifyNever(() => mic.setMicrophoneEnabled(true));
    });

    test('repeats are no-ops', () async {
      line(micOn: true);
      await svc.applySystemHold('room-1');
      await svc.applySystemHold('room-1');
      verify(() => mic.setMicrophoneEnabled(false)).called(1);
      await svc.applySystemResume('room-1');
      await svc.applySystemResume('room-1');
      verify(() => mic.setMicrophoneEnabled(true)).called(1);
    });

    test('system mute applies, but not while held', () async {
      line(micOn: true);
      await svc.applySystemMute('room-1', true);
      verify(() => mic.setMicrophoneEnabled(false)).called(1);
      await svc.applySystemHold('room-1');
      clearInteractions(mic);
      await svc.applySystemMute('room-1', false);
      verifyNever(() => mic.setMicrophoneEnabled(true));
    });

    test('holdAndSwitch after a system hold remembers the mic was on', () async {
      // A second line must already exist for holdAndSwitch to have
      // somewhere to send room-1 to — created first so room-1 (via line())
      // ends up the active one.
      svc.setRoom(_makeRoom(), 'room-2', 'conv-2');
      line(micOn: true);
      await svc.applySystemHold('room-1');
      // The mock doesn't simulate real hardware, so isMicrophoneEnabled()
      // still says true after setMicrophoneEnabled(false) above — reflect
      // what the mic actually reads once the hold has silenced it, as it
      // would on a real device by the time the app switches lines.
      when(() => mic.isMicrophoneEnabled()).thenReturn(false);

      await svc.holdAndSwitch('room-2'); // in-app switch away from room-1
      await svc.holdAndSwitch('room-1'); // ...and back

      verify(() => mic.setMicrophoneEnabled(true)).called(1);
    });
  });

  group('line hooks', () {
    final ended = <String>[];
    final holds = <String>[];

    setUp(() {
      ended.clear();
      holds.clear();
      svc.onLineEnded = (room) async => ended.add(room);
      svc.onLineHoldChanged = (room, onHold) async => holds.add('$room:$onHold');
    });

    tearDown(() {
      svc.onLineEnded = null;
      svc.onLineHoldChanged = null;
    });

    test('every path that removes a line reports it', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      svc.setRoom(_makeRoom(), 'b', 'c2');
      await svc.endLine('b');
      expect(ended, ['b']);
      svc.notifyEnded();
      expect(ended, ['b', 'a']);
      svc.setRoom(_makeRoom(), 'x', 'c3');
      svc.setRoom(_makeRoom(), 'y', 'c4');
      await svc.endCall();
      expect(ended, containsAll(['x', 'y']));
    });

    test('line switching is mirrored as holds', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      svc.setRoom(_makeRoom(), 'b', 'c2');
      await svc.holdAndSwitch('a');
      expect(holds, ['b:true', 'a:false']);
    });

    test('ending the active line brings the next one back', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      svc.setRoom(_makeRoom(), 'b', 'c2');
      await svc.endLine('b');
      expect(holds, ['a:false']);
    });

    test('connectInBackground holds the current line before dialling', () async {
      // sl<DioClient>() must throw so connectInBackground fails right after
      // holding the current line, without a real join request. Registered
      // here (not in the group setUp) so the other line-hooks tests, which
      // never touch sl, are unaffected.
      final client = MockDioClient();
      when(() => client.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('network down'));
      sl.registerLazySingleton<DioClient>(() => client);
      addTearDown(() => sl.unregister<DioClient>());

      svc.setRoom(_makeRoom(), 'a', 'c1');
      final result = await svc.connectInBackground('b', 'c2');

      expect(result, isFalse);
      expect(holds, ['a:true']);
    });
  });
}
