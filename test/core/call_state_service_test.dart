import 'dart:async';
import 'package:fake_async/fake_async.dart';
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

/// Build a MockRoom with a stubbed LocalParticipant whose mic state is
/// tracked like real hardware would: isMicrophoneEnabled() reflects the last
/// setMicrophoneEnabled() call instead of a fixed snapshot, so tests can
/// assert the final mic state instead of only counting calls.
MockRoom _makeRoom({bool micEnabled = true}) {
  final room = MockRoom();
  final participant = MockLocalParticipant();
  var micOn = micEnabled;
  when(() => room.localParticipant).thenReturn(participant);
  when(() => participant.isMicrophoneEnabled()).thenAnswer((_) => micOn);
  when(() => participant.setMicrophoneEnabled(any())).thenAnswer((invocation) async {
    micOn = invocation.positionalArguments[0] as bool;
    return null;
  });
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

    test('reconnecting an existing line carries its system hold over', () {
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1');
      svc.activeLine!.heldBySystem = true;
      svc.activeLine!.micOnBeforeSystemHold = true;

      // _startManualReconnect: same roomName, fresh Room/CallLine.
      svc.setRoom(_makeRoom(), 'room-1', 'conv-1');

      expect(svc.activeLine!.heldBySystem, isTrue);
      expect(svc.activeLine!.micOnBeforeSystemHold, isTrue);
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

    test('a target that ends mid-switch does not strand the current line held (N3)', () async {
      svc.setRoom(_makeRoom(), 'b', 'c2'); // will be the target — ends mid-flight

      // 'a' is current (created last, so active); its setMicrophoneEnabled
      // (false) is gated by a Completer so 'b' can be ended while that
      // await is still pending — the exact race this guards against.
      final roomA = MockRoom();
      final micA = MockLocalParticipant();
      final gate = Completer<void>();
      var micAOn = true;
      when(() => roomA.localParticipant).thenReturn(micA);
      when(() => micA.isMicrophoneEnabled()).thenAnswer((_) => micAOn);
      when(() => micA.setMicrophoneEnabled(any())).thenAnswer((invocation) async {
        await gate.future;
        micAOn = invocation.positionalArguments[0] as bool;
        return null;
      });
      when(() => micA.setCameraEnabled(any())).thenAnswer((_) async => null);
      when(() => roomA.disconnect()).thenAnswer((_) async {});
      svc.setRoom(roomA, 'a', 'c1'); // now active

      final switching = svc.holdAndSwitch('b'); // blocks inside the gated mic-off await
      await Future.delayed(Duration.zero);

      await svc.endLine('b'); // target ends while 'a' is still being muted
      gate.complete(); // release the gated setMicrophoneEnabled(false)
      await switching;

      expect(svc.activeLine!.roomName, 'a'); // never switched onto the gone line
      expect(svc.activeLine!.isOnHold, isFalse); // hold undone, not stranded
      expect(micA.isMicrophoneEnabled(), isTrue); // mic restored
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

    test('restores the mic on the line it switches back to', () {
      final room1 = _makeRoom(micEnabled: false);
      svc.setRoom(room1, 'room-1', null);
      svc.allLines.first.isOnHold = true;
      svc.allLines.first.wasMuted = false; // mic was on before the hold

      svc.setRoom(_makeRoom(), 'room-2', null);
      svc.notifyEnded(); // ends room-2 (active), switches back to room-1

      final p1 = room1.localParticipant as MockLocalParticipant;
      expect(p1.isMicrophoneEnabled(), isTrue);
    });

    test('does not touch the mic when switching back to a system-held line', () {
      final room1 = _makeRoom(micEnabled: false);
      svc.setRoom(room1, 'room-1', null);
      svc.allLines.first.isOnHold = true;
      svc.allLines.first.wasMuted = false; // would want the mic on...
      svc.allLines.first.heldBySystem = true; // ...but the system still owns it

      svc.setRoom(_makeRoom(), 'room-2', null);
      svc.notifyEnded();

      final p1 = room1.localParticipant as MockLocalParticipant;
      expect(p1.isMicrophoneEnabled(), isFalse);
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

    test('holdAndSwitch after a system hold remembers the mic was on, but '
        'only applySystemResume may turn it back on', () async {
      // A second line must already exist for holdAndSwitch to have
      // somewhere to send room-1 to — created first so room-1 (via line())
      // ends up the active one.
      svc.setRoom(_makeRoom(), 'room-2', 'conv-2');
      line(micOn: true);
      await svc.applySystemHold('room-1'); // mic off; micOnBeforeSystemHold=true

      await svc.holdAndSwitch('room-2'); // in-app switch away from room-1
      await svc.holdAndSwitch('room-1'); // ...and back

      // Still heldBySystem — holdAndSwitch must not have touched the mic,
      // even though wasMuted correctly remembers "was on" underneath.
      expect(mic.isMicrophoneEnabled(), isFalse);
      expect(svc.activeLine!.wasMuted, isFalse);

      await svc.applySystemResume('room-1'); // only this may turn it on
      expect(mic.isMicrophoneEnabled(), isTrue);
    });

    test('mute while system-held records intent, never touches the mic', () async {
      line(micOn: true);
      await svc.applySystemHold('room-1');
      clearInteractions(mic);

      await svc.applySystemMute('room-1', true); // "mute" via the system UI
      verifyNever(() => mic.setMicrophoneEnabled(any()));
      expect(svc.activeLine!.micOnBeforeSystemHold, isFalse);

      await svc.applySystemMute('room-1', false); // "unmute"
      verifyNever(() => mic.setMicrophoneEnabled(any()));
      expect(svc.activeLine!.micOnBeforeSystemHold, isTrue);

      await svc.applySystemResume('room-1');
      expect(mic.isMicrophoneEnabled(), isTrue); // honors the last recorded intent
    });

    test('mute while app-held records wasMuted, never touches the mic', () async {
      line(micOn: true);
      final held = svc.activeLine!;
      held.isOnHold = true; // as holdAndSwitch/endLine leave the held line
      clearInteractions(mic);

      await svc.applySystemMute('room-1', true);
      verifyNever(() => mic.setMicrophoneEnabled(any()));
      expect(held.wasMuted, isTrue);

      await svc.applySystemMute('room-1', false);
      verifyNever(() => mic.setMicrophoneEnabled(any()));
      expect(held.wasMuted, isFalse);
    });

    test('resume while still app-held folds its intent into wasMuted (N2)', () async {
      line(micOn: true);
      final l = svc.activeLine!;
      l.isOnHold = true; // both holds active at once
      l.wasMuted = true; // stale — as if the app hold wanted the mic off
      await svc.applySystemHold('room-1'); // now also heldBySystem

      await svc.applySystemMute('room-1', false); // "unmute" via the system UI
      expect(l.micOnBeforeSystemHold, isTrue); // heldBySystem branch wins

      await svc.applySystemResume('room-1'); // system lets go; isOnHold still true

      expect(l.heldBySystem, isFalse);
      // Folded from micOnBeforeSystemHold, not left at the stale `true` —
      // the in-app switch back reads wasMuted, not micOnBeforeSystemHold.
      expect(l.wasMuted, isFalse);
    });

    test('setLineMuted while system-held records intent for the resume to apply', () async {
      // e.g. the in-call assistant hands the mic back mid-hold.
      line(micOn: false);
      await svc.applySystemHold('room-1');

      await svc.setLineMuted('room-1', false); // hand-back: mic wanted ON

      await svc.applySystemResume('room-1');
      expect(mic.isMicrophoneEnabled(), isTrue);
    });
  });

  // "Hold & Accept" can land while the LiveKit join for that room is still
  // in flight — before setRoom has ever created its CallLine.
  group('pending system holds', () {
    test('a hold for an unknown room is applied once the line appears', () async {
      await svc.applySystemHold('not-yet-joined');
      svc.setRoom(_makeRoom(), 'not-yet-joined', 'conv-1');

      expect(svc.activeLine!.heldBySystem, isTrue);
      expect(svc.activeLine!.micOnBeforeSystemHold, isTrue);
    });

    test('resume for an unknown room forgets the pending hold', () async {
      await svc.applySystemHold('not-yet-joined');
      await svc.applySystemResume('not-yet-joined');
      svc.setRoom(_makeRoom(), 'not-yet-joined', 'conv-1');

      expect(svc.activeLine!.heldBySystem, isFalse);
    });

    test('endCall clears pending holds', () async {
      await svc.applySystemHold('not-yet-joined');
      await svc.endCall();
      svc.setRoom(_makeRoom(), 'not-yet-joined', 'conv-1');

      expect(svc.activeLine!.heldBySystem, isFalse);
    });

    test('endLine clears a pending hold whose room never became a line (N1)', () async {
      // Screen hang-up / system end of a room whose join hadn't produced a
      // CallLine yet. Meeting/personal rooms are reused, so without this the
      // *next* line for 'r' would start heldBySystem with no CallKit hold
      // behind it — mic recorded muted but never actually turned off, and a
      // later real hold would hit applySystemHold's already-held early
      // return and never turn it off either.
      await svc.applySystemHold('r');
      await svc.endLine('r'); // no line exists yet — just clears the pending hold

      svc.setRoom(_makeRoom(), 'r', 'conv-1'); // room reused for a later call

      expect(svc.activeLine!.heldBySystem, isFalse);
      expect(svc.activeLine!.room.localParticipant!.isMicrophoneEnabled(), isTrue);
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
      // Exact order, not just membership: _lines preserves insertion order,
      // and endCall reports in that order.
      expect(ended, ['b', 'a', 'x', 'y']);
    });

    test('nothing is reported for a line or room that never existed', () async {
      await svc.endLine('nope');
      await svc.applySystemResume('nope');
      await svc.applySystemMute('nope', true);

      expect(ended, isEmpty);
      expect(holds, isEmpty);
    });

    test('line switching is mirrored as holds', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      svc.setRoom(_makeRoom(), 'b', 'c2');
      await svc.holdAndSwitch('a');
      expect(holds, ['b:true', 'a:false']);
    });

    test('holdAndSwitch to the active non-held line reports nothing', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      await svc.holdAndSwitch('a'); // already active, not held — no-op

      expect(holds, isEmpty);
    });

    test('holdAndSwitch to a stuck-held active line still clears it', () async {
      // A stuck isOnHold on the active line (e.g. from an interrupted
      // switch) still shows the swap icon on the dashboard; tapping it
      // calls holdAndSwitch on the same room, which must still clear the
      // flag and report the unhold, unlike the true no-op above.
      svc.setRoom(_makeRoom(), 'a', 'c1');
      svc.activeLine!.isOnHold = true;

      await svc.holdAndSwitch('a');

      expect(holds, ['a:false']);
      expect(svc.activeLine!.isOnHold, isFalse);
    });

    test('ending the active line brings the next one back', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      svc.setRoom(_makeRoom(), 'b', 'c2');
      await svc.endLine('b');
      expect(holds, ['a:false']);
    });

    test('notifyEnded reports the unhold when it switches to the next line', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      svc.setRoom(_makeRoom(), 'b', 'c2');
      svc.notifyEnded(); // ends 'b' (active), switches to 'a'
      expect(holds, ['a:false']);
    });

    test('a hook that throws synchronously does not abort endCall', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      final room = svc.allLines.first.room as MockRoom;
      // Not `async` on purpose: this throws to its caller immediately,
      // unlike the group's default async hook — the case Future.sync
      // guards against.
      svc.onLineEnded = (roomName) {
        throw Exception('boom');
      };

      await svc.endCall(); // must not throw, and must still disconnect

      verify(() => room.disconnect()).called(1);
      expect(svc.isInCall, isFalse);
    });

    test('a failed connectInBackground undoes the hold on the previous line', () async {
      // Registering a throwing DioClient makes the failure explicit and
      // deliberate — with nothing registered at all, sl<DioClient>() itself
      // throws inside this same try block and would fail the test the same
      // way, just less obviously on purpose. Registered here (not in the
      // group setUp) so the other line-hooks tests, which never touch sl,
      // are unaffected.
      final client = MockDioClient();
      when(() => client.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('network down'));
      sl.registerLazySingleton<DioClient>(() => client);
      addTearDown(() => sl.unregister<DioClient>());

      final roomA = _makeRoom();
      svc.setRoom(roomA, 'a', 'c1');
      final result = await svc.connectInBackground('b', 'c2');

      expect(result, isFalse);
      // Held, then un-held again once the join failed — not left stranded.
      expect(holds, ['a:true', 'a:false']);
      expect(svc.activeLine!.isOnHold, isFalse);
      expect((roomA.localParticipant as MockLocalParticipant).isMicrophoneEnabled(), isTrue);
    });

    test('connectInBackground reads wasMuted from micOnBeforeSystemHold when '
        'the current line is system-held', () async {
      final client = MockDioClient();
      when(() => client.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('network down')); // fail fast; only the
      // hold computed before the join matters to this test.
      sl.registerLazySingleton<DioClient>(() => client);
      addTearDown(() => sl.unregister<DioClient>());

      svc.setRoom(_makeRoom(), 'a', 'c1');
      await svc.applySystemHold('a'); // mic off; micOnBeforeSystemHold=true

      await svc.connectInBackground('b', 'c2');

      // Must come from micOnBeforeSystemHold (mic was on → not muted), not
      // from the live mic reading — that's already off because of the
      // system hold and would wrongly say "was muted" if read directly.
      expect(svc.allLines.firstWhere((l) => l.roomName == 'a').wasMuted, isFalse);
    });
  });

  // ── Step 0: room disconnects before the line is reported ended ──────────
  //
  // onLineEnded is wired (main.dart) to SystemCallRegistry.endConversation,
  // which ends this conversation's CallKit call and releases manual WebRTC
  // audio ownership. A room still connected at that point would have WebRTC
  // grab the audio unit and activate the session on its own — mid a
  // WhatsApp/cellular call, if this line had been held for one. So the room
  // must disconnect first.
  group('room disconnects before the line is reported ended', () {
    test('endLine: hook only fires after room.disconnect() completes', () async {
      final log = <String>[];
      final room = _makeRoom();
      when(() => room.disconnect()).thenAnswer((_) async {
        log.add('disconnect:a');
      });
      svc.setRoom(room, 'a', 'c1');
      svc.onLineEnded = (roomName) async => log.add('ended:$roomName');
      addTearDown(() => svc.onLineEnded = null);

      await svc.endLine('a');

      expect(log, ['disconnect:a', 'ended:a']);
    });

    test('endCall: every room disconnects before any line is reported ended', () async {
      final log = <String>[];
      final roomA = _makeRoom();
      final roomB = _makeRoom();
      when(() => roomA.disconnect()).thenAnswer((_) async => log.add('disconnect:a'));
      when(() => roomB.disconnect()).thenAnswer((_) async => log.add('disconnect:b'));
      svc.setRoom(roomA, 'a', 'c1');
      svc.setRoom(roomB, 'b', 'c2');
      svc.onLineEnded = (roomName) async => log.add('ended:$roomName');
      addTearDown(() => svc.onLineEnded = null);

      await svc.endCall();

      // Both disconnects land before either "ended" report — endCall
      // disconnects every room in parallel, not one line at a time.
      final firstEnded = log.indexWhere((e) => e.startsWith('ended:'));
      expect(firstEnded, 2);
      expect(log.sublist(0, 2), unorderedEquals(['disconnect:a', 'disconnect:b']));
      expect(log.sublist(2), unorderedEquals(['ended:a', 'ended:b']));
    });

    test('endLine: a hung room.disconnect() does not delay the report past the 2s timeout', () {
      fakeAsync((async) {
        final gate = Completer<void>(); // never completes
        final room = _makeRoom();
        when(() => room.disconnect()).thenAnswer((_) => gate.future);
        svc.setRoom(room, 'a', 'c1');
        final log = <String>[];
        svc.onLineEnded = (roomName) async => log.add(roomName);
        addTearDown(() => svc.onLineEnded = null);

        unawaited(svc.endLine('a'));
        async.elapse(const Duration(seconds: 2));

        expect(log, ['a']);
      });
    });

    test('endCall: a hung room.disconnect() does not delay the report past the 2s timeout', () {
      fakeAsync((async) {
        final gate = Completer<void>(); // never completes
        final room = _makeRoom();
        when(() => room.disconnect()).thenAnswer((_) => gate.future);
        svc.setRoom(room, 'a', 'c1');
        final log = <String>[];
        svc.onLineEnded = (roomName) async => log.add(roomName);
        addTearDown(() => svc.onLineEnded = null);

        unawaited(svc.endCall());
        async.elapse(const Duration(seconds: 2));

        expect(log, ['a']);
      });
    });

    test('endLine: a hold landing while the disconnect is in flight does not leak '
        'into the room\'s next line (S0)', () async {
      final gate = Completer<void>();
      final room = _makeRoom();
      when(() => room.disconnect()).thenAnswer((_) => gate.future);
      svc.setRoom(room, 'r', 'c1');

      final ending = svc.endLine('r');
      await Future.delayed(Duration.zero); // let it reach the gated disconnect

      // The line was already removed (top of endLine), so this is read as a
      // hold for an unknown room and re-added to _pendingSystemHolds — the
      // exact leak this test guards against.
      await svc.applySystemHold('r');

      gate.complete();
      await ending;

      // Room 'r' reused for a new call — must not inherit the leaked hold.
      svc.setRoom(_makeRoom(), 'r', 'c2');
      expect(svc.activeLine!.heldBySystem, isFalse);
    });

    test('endCall: a hold landing while a disconnect is in flight does not leak '
        'into that room\'s next line (S0)', () async {
      final gate = Completer<void>();
      final room = _makeRoom();
      when(() => room.disconnect()).thenAnswer((_) => gate.future);
      svc.setRoom(room, 'r', 'c1');

      final ending = svc.endCall();
      await Future.delayed(Duration.zero);

      await svc.applySystemHold('r');

      gate.complete();
      await ending;

      svc.setRoom(_makeRoom(), 'r', 'c2');
      expect(svc.activeLine!.heldBySystem, isFalse);
    });
  });

  // ── System End while still joining (background connect) ─────────────────

  group('abandonBackgroundConnect', () {
    test('cancels the join in flight, returns its conv id, no line is created, '
        'and the line it held comes back off hold', () async {
      // Line 'a' is active; connectInBackground will hold it for the new join.
      final roomA = _makeRoom();
      svc.setRoom(roomA, 'a', 'c1');

      final client = MockDioClient();
      final joinGate = Completer<Map<String, dynamic>>();
      when(() => client.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) => joinGate.future);
      sl.registerLazySingleton<DioClient>(() => client);
      addTearDown(() => sl.unregister<DioClient>());

      final connecting = svc.connectInBackground('r', 'conv-r');
      await Future.delayed(Duration.zero); // let it reach the gated HTTP join

      expect(svc.isBackgroundConnecting, isTrue);
      final convId = svc.abandonBackgroundConnect('r');
      expect(convId, 'conv-r');
      expect(svc.isBackgroundConnecting, isFalse);

      // Let the suspended join resume: it must see the bumped generation and
      // cancel itself instead of completing the call.
      joinGate.complete({'token': 'unused'});
      final result = await connecting;

      expect(result, isFalse);
      expect(svc.allLines.map((l) => l.roomName), isNot(contains('r')));
      final lineA = svc.allLines.firstWhere((l) => l.roomName == 'a');
      expect(lineA.isOnHold, isFalse);
      expect((roomA.localParticipant as MockLocalParticipant).isMicrophoneEnabled(), isTrue);
    });

    test('a room that is not the join in flight is not abandoned', () async {
      expect(svc.abandonBackgroundConnect('nope'), isNull);
    });

    test('waitForBackgroundConnect unblocks once the join it was waiting on is abandoned', () async {
      final client = MockDioClient();
      final joinGate = Completer<Map<String, dynamic>>();
      when(() => client.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) => joinGate.future);
      sl.registerLazySingleton<DioClient>(() => client);
      addTearDown(() => sl.unregister<DioClient>());

      final connecting = svc.connectInBackground('r', 'conv-r');
      await Future.delayed(Duration.zero);

      final waiting = svc.waitForBackgroundConnect();
      svc.abandonBackgroundConnect('r');

      expect(await waiting.timeout(const Duration(seconds: 1)), isFalse);
      joinGate.complete({'token': 'unused'}); // let connectInBackground unwind
      await connecting;
    });
  });

  group('system ended marker', () {
    test('consumeSystemEnded is true once, then forgets', () {
      svc.markSystemEnded('r');
      expect(svc.consumeSystemEnded('r'), isTrue);
      expect(svc.consumeSystemEnded('r'), isFalse);
    });

    test('a room that was never marked reads false', () {
      expect(svc.consumeSystemEnded('never-marked'), isFalse);
    });

    test('setRoom forgets a stale mark for the room name it reuses', () {
      svc.markSystemEnded('r');
      svc.setRoom(_makeRoom(), 'r', 'c1');
      expect(svc.consumeSystemEnded('r'), isFalse);
    });

    test('endCall clears every mark', () async {
      svc.markSystemEnded('r');
      await svc.endCall();
      expect(svc.consumeSystemEnded('r'), isFalse);
    });
  });
}
