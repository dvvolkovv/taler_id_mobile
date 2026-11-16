// The fake room drives LiveKit's own EventsEmitter — the same one a real
// Room delivers these events through — and `emit` is internal to the package.
// ignore_for_file: invalid_use_of_internal_member

import 'dart:collection';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/services/call_state_service.dart';

// A line nobody else is watching — the call minimized behind the dashboard's
// "return to call" banner, or a line on hold — must still end when its call
// is over: the peer left the room without a `call_ended` reaching us (their
// app died, lost network, our socket was down), or the room itself dropped.

class _Peer extends Mock implements lk.RemoteParticipant {
  _Peer(this.identity);

  @override
  final String identity;
}

class _Room extends Mock implements lk.Room {
  final _events = lk.EventsEmitter<lk.RoomEvent>();
  final _remotes = <String, lk.RemoteParticipant>{};
  var state = lk.ConnectionState.connected;

  @override
  lk.ConnectionState get connectionState => state;

  @override
  UnmodifiableMapView<String, lk.RemoteParticipant> get remoteParticipants =>
      UnmodifiableMapView(_remotes);

  @override
  lk.EventsListener<lk.RoomEvent> createListener({bool synchronized = false}) =>
      lk.EventsListener<lk.RoomEvent>(_events, synchronized: synchronized);

  /// Already in the room when the line is created (answered from background).
  void present(String identity) => _remotes[identity] = _Peer(identity);

  void join(String identity) {
    final p = _Peer(identity);
    _remotes[identity] = p;
    _events.emit(lk.ParticipantConnectedEvent(participant: p));
  }

  void leave(String identity) {
    final p = _remotes.remove(identity)!;
    _events.emit(lk.ParticipantDisconnectedEvent(participant: p));
  }

  void drop() {
    state = lk.ConnectionState.disconnected;
    final gone = _remotes.values.toList();
    _remotes.clear();
    for (final p in gone) {
      _events.emit(lk.ParticipantDisconnectedEvent(participant: p));
    }
    _events.emit(lk.RoomDisconnectedEvent());
  }
}

_Room _room({List<String> present = const []}) {
  final room = _Room();
  for (final id in present) {
    room.present(id);
  }
  when(() => room.disconnect()).thenAnswer((_) async {});
  return room;
}

List<String> _lines(CallStateService svc) => svc.allLines.map((l) => l.roomName).toList();

void main() {
  final svc = CallStateService.instance;

  setUp(() async {
    await svc.endCall();
  });

  tearDown(() async {
    await svc.endCall();
  });

  test('a minimized call ends a while after the peer has left', () {
    fakeAsync((async) {
      final room = _room(present: ['bob']);
      svc.setRoom(room, 'r1', 'c1');

      room.leave('bob');
      async.elapse(const Duration(seconds: 9));
      expect(svc.isInCall, isTrue, reason: 'a peer reconnecting leaves the room for a moment');

      async.elapse(const Duration(seconds: 2));
      expect(svc.isInCall, isFalse);
      verify(() => room.disconnect()).called(1);
    });
  });

  test('a peer who joined after the line was created counts too', () {
    fakeAsync((async) {
      final room = _room();
      svc.setRoom(room, 'r1', 'c1');

      room.join('bob');
      async.elapse(const Duration(seconds: 1));
      room.leave('bob');
      async.elapse(const Duration(seconds: 11));

      expect(svc.isInCall, isFalse);
    });
  });

  test('a peer back within the grace period keeps the call', () {
    fakeAsync((async) {
      final room = _room(present: ['bob']);
      svc.setRoom(room, 'r1', 'c1');

      room.leave('bob');
      async.elapse(const Duration(seconds: 4));
      room.join('bob');
      async.elapse(const Duration(seconds: 30));

      expect(svc.isInCall, isTrue);
    });
  });

  test('nobody has answered yet: an empty room is just ringing', () {
    fakeAsync((async) {
      final room = _room();
      svc.setRoom(room, 'r1', 'c1');

      // Bots coming and going are not a peer.
      room.join('meeting-recorder');
      room.leave('meeting-recorder');
      async.elapse(const Duration(seconds: 60));

      expect(svc.isInCall, isTrue);
    });
  });

  test('a dropped room ends the minimized call right away', () {
    fakeAsync((async) {
      final room = _room(present: ['bob']);
      svc.setRoom(room, 'r1', 'c1');

      room.drop();
      async.flushMicrotasks();

      expect(svc.isInCall, isFalse);
    });
  });

  test('the line on the call screen is left to the screen until it closes', () {
    fakeAsync((async) {
      final screen = Object();
      final room = _room(present: ['bob']);
      svc.setRoom(room, 'r1', 'c1');
      svc.setCallUi(screen, true);

      room.leave('bob');
      async.elapse(const Duration(seconds: 30));
      expect(svc.isInCall, isTrue, reason: 'the screen hangs up an emptied room itself');

      // Minimized before its own 3 s timer fired.
      svc.setCallUi(screen, false);
      async.elapse(const Duration(seconds: 9));
      expect(svc.isInCall, isTrue);
      async.elapse(const Duration(seconds: 2));
      expect(svc.isInCall, isFalse);
    });
  });

  test('a dropped room on the call screen is left to its reconnect', () {
    fakeAsync((async) {
      final screen = Object();
      final room = _room(present: ['bob']);
      svc.setRoom(room, 'r1', 'c1');
      svc.setCallUi(screen, true);

      room.drop();
      async.elapse(const Duration(seconds: 30));

      expect(svc.isInCall, isTrue);
      svc.setCallUi(screen, false);
    });
  });

  test('a held line ends while the screen shows another one', () {
    fakeAsync((async) {
      final screen = Object();
      final held = _room(present: ['bob']);
      final shown = _room(present: ['carol']);
      svc.setRoom(held, 'a', 'ca');
      svc.setRoom(shown, 'b', 'cb');
      svc.setCallUi(screen, true);
      async.flushMicrotasks();

      held.leave('bob');
      async.elapse(const Duration(seconds: 11));

      expect(_lines(svc), ['b']);
      expect(svc.roomName, 'b');
      svc.setCallUi(screen, false);
    });
  });

  test('a line that leaves the screen is watched from then on', () {
    fakeAsync((async) {
      final screen = Object();
      final first = _room(present: ['bob']);
      svc.setRoom(first, 'a', 'ca');
      svc.setCallUi(screen, true);

      first.leave('bob');
      async.elapse(const Duration(seconds: 2));
      // Another call becomes the active one before the screen hung up 'a'.
      svc.setRoom(_room(present: ['carol']), 'b', 'cb');
      async.elapse(const Duration(seconds: 11));

      expect(_lines(svc), ['b']);
      svc.setCallUi(screen, false);
    });
  });

  test('our own reconnect empties the room for a while — not the end', () {
    fakeAsync((async) {
      final room = _room(present: ['bob']);
      svc.setRoom(room, 'r1', 'c1');

      room.state = lk.ConnectionState.reconnecting;
      room.leave('bob');
      async.elapse(const Duration(seconds: 25));
      expect(svc.isInCall, isTrue);

      room.state = lk.ConnectionState.connected;
      room.join('bob');
      async.elapse(const Duration(seconds: 30));
      expect(svc.isInCall, isTrue);
    });
  });

  test('a reconnect replacing the room keeps the peer seen before it', () {
    fakeAsync((async) {
      final before = _room(present: ['bob']);
      svc.setRoom(before, 'r1', 'c1');

      // The screen's manual reconnect: a fresh room for the same line, the
      // peer not (yet) in it.
      final after = _room();
      svc.setRoom(after, 'r1', 'c1');
      async.elapse(const Duration(seconds: 11));

      expect(svc.isInCall, isFalse, reason: 'the old room\'s peer already answered this call');
    });
  });

  test('the old room of a replaced line no longer ends it', () {
    fakeAsync((async) {
      final before = _room(present: ['bob']);
      svc.setRoom(before, 'r1', 'c1');
      final after = _room(present: ['bob']);
      svc.setRoom(after, 'r1', 'c1');

      before.drop();
      async.elapse(const Duration(seconds: 30));

      expect(svc.isInCall, isTrue);
      expect(svc.room, same(after));
    });
  });

  test('an AI twin call is not ended by the twin leaving', () {
    fakeAsync((async) {
      final room = _room(present: ['agent-twin']);
      svc.setRoom(room, 'r1', 'c1');
      svc.markAiTwinActive('r1');

      room.leave('agent-twin');
      async.elapse(const Duration(seconds: 30));

      expect(svc.isInCall, isTrue);
      svc.unmarkAiTwinActive('r1');
    });
  });

  test('a line ended elsewhere stops being watched', () {
    fakeAsync((async) {
      final room = _room(present: ['bob']);
      svc.setRoom(room, 'r1', 'c1');
      room.leave('bob');
      async.elapse(const Duration(seconds: 2));

      svc.endLine('r1');
      async.flushMicrotasks();
      // Same room name reused by the next call: the old timer must not end it.
      svc.setRoom(_room(), 'r1', 'c1');
      async.elapse(const Duration(seconds: 30));

      expect(svc.isInCall, isTrue);
    });
  });
}
