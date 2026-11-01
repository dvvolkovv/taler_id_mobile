import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/interpreter/room/interpreter_room_controller.dart';
import 'package:taler_id_mobile/features/interpreter/room/interpreter_room_port.dart';
import 'package:taler_id_mobile/features/interpreter/room/interpreter_signal.dart';

import '../fakes.dart';

void main() {
  late FakeRoomPort port;
  late InterpreterRoomController controller;

  setUp(() {
    port = FakeRoomPort();
    controller = InterpreterRoomController(port);
  });

  tearDown(() async {
    await port.close();
  });

  group('start', () {
    test('restricts the mic to the agent before publishing it', () async {
      await controller.start(url: 'wss://lk', token: 'tok', micOn: true);

      expect(port.calls, [
        'connect(wss://lk, tok)',
        'restrictMicTo(voice-interpreter)',
        'setMicrophone(true)',
      ]);
    });

    test('still restricts before publishing when starting muted', () async {
      await controller.start(url: 'wss://lk', token: 'tok', micOn: false);

      expect(port.calls, [
        'connect(wss://lk, tok)',
        'restrictMicTo(voice-interpreter)',
        'setMicrophone(false)',
      ]);
    });
  });

  group('what was in the room before me', () {
    const myTrack = RoomTrackRef(
      participantIdentity: 'voice-interpreter',
      trackName: 'interp-for-me-user',
      trackSid: 'TR_MINE',
    );

    test('subscribes to my track the agent published before I connected',
        () async {
      // The guest always joins after the agent: its track is already there.
      port.present = ['voice-interpreter', 'host-user#bbbbbbbb'];
      port.tracks = [
        myTrack,
        const RoomTrackRef(
          participantIdentity: 'voice-interpreter',
          trackName: 'interp-for-host-user',
          trackSid: 'TR_HOST',
        ),
      ];
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      await controller.start(url: 'wss://lk', token: 'tok', micOn: true);
      await pumpEventQueue();

      expect(port.subscribed, [myTrack]);
      expect(updates, [
        const AgentJoined(),
        const PartnerJoined('host-user#bbbbbbbb'),
      ]);
      expect(controller.agentPresent, isTrue);
    });

    test('subscribes again to my track after a reconnect', () async {
      await controller.start(url: 'wss://lk', token: 'tok', micOn: true);
      port.tracks = [myTrack];

      port.emit(const Reconnected());
      await pumpEventQueue();

      expect(port.subscribed, [myTrack]);
    });
  });

  group('track subscription', () {
    setUp(() async {
      await controller.start(url: 'wss://lk', token: 'tok', micOn: true);
    });

    test('subscribes to my own interp-for track published by the agent',
        () async {
      const track = RoomTrackRef(
        participantIdentity: 'voice-interpreter',
        trackName: 'interp-for-me-user',
        trackSid: 'TR_1',
      );
      port.emit(TrackPublished(track));
      await pumpEventQueue();

      expect(port.subscribed, [track]);
    });

    test('ignores the partner\'s own mic track', () async {
      const track = RoomTrackRef(
        participantIdentity: 'partner-user#bbbbbbbb',
        trackName: 'microphone',
        trackSid: 'TR_2',
      );
      port.emit(TrackPublished(track));
      await pumpEventQueue();

      expect(port.subscribed, isEmpty);
    });

    test('ignores the other listener\'s interp-for track from the agent',
        () async {
      const track = RoomTrackRef(
        participantIdentity: 'voice-interpreter',
        trackName: 'interp-for-partner-user',
        trackSid: 'TR_3',
      );
      port.emit(TrackPublished(track));
      await pumpEventQueue();

      expect(port.subscribed, isEmpty);
    });

    test('ignores a track with the right name from a non-agent identity',
        () async {
      const track = RoomTrackRef(
        participantIdentity: 'partner-user#bbbbbbbb',
        trackName: 'interp-for-me-user',
        trackSid: 'TR_4',
      );
      port.emit(TrackPublished(track));
      await pumpEventQueue();

      expect(port.subscribed, isEmpty);
    });
  });

  group('participants', () {
    setUp(() async {
      await controller.start(url: 'wss://lk', token: 'tok', micOn: true);
    });

    test('a different base identity joining is the partner', () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(const ParticipantJoined('partner-user#bbbbbbbb'));
      await pumpEventQueue();

      expect(updates, [const PartnerJoined('partner-user#bbbbbbbb')]);
    });

    test('my own other device joining is NOT reported as a partner', () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(const ParticipantJoined('me-user#cccccccc'));
      await pumpEventQueue();

      expect(updates, isEmpty);
    });

    test('the agent joining/leaving is reported distinctly, not as a partner',
        () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(const ParticipantJoined('voice-interpreter'));
      port.emit(const ParticipantLeft('voice-interpreter'));
      await pumpEventQueue();

      expect(updates, [const AgentJoined(), const AgentLeft()]);
      expect(controller.agentPresent, isFalse);
    });

    test('a partner leaving is reported', () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(const ParticipantLeft('partner-user#bbbbbbbb'));
      await pumpEventQueue();

      expect(updates, [const PartnerLeft('partner-user#bbbbbbbb')]);
    });
  });

  group('data signals', () {
    setUp(() async {
      await controller.start(url: 'wss://lk', token: 'tok', micOn: true);
    });

    test('parses interp-topic data from the agent', () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(DataReceived(
        topic: 'interp',
        bytes: parseToBytes({
          'type': 'speaking',
          'speaker': 'partner-user',
          'on': true,
        }),
        fromIdentity: 'voice-interpreter',
      ));
      await pumpEventQueue();

      expect(updates, hasLength(1));
      final signal = (updates.single as Signal).signal;
      expect(signal, isA<SpeakingSignal>());
    });

    test('ignores interp-topic data from the partner, not just the agent',
        () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(DataReceived(
        topic: 'interp',
        bytes: parseToBytes({
          'type': 'speaking',
          'speaker': 'partner-user',
          'on': true,
        }),
        fromIdentity: 'partner-user#bbbbbbbb',
      ));
      await pumpEventQueue();

      expect(updates, isEmpty);
    });

    test('ignores data on other topics even from the agent', () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(DataReceived(
        topic: 'chat',
        bytes: parseToBytes({
          'type': 'speaking',
          'speaker': 'partner-user',
          'on': true,
        }),
        fromIdentity: 'voice-interpreter',
      ));
      await pumpEventQueue();

      expect(updates, isEmpty);
    });

    test('a signal that fails to parse produces no update', () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(DataReceived(
        topic: 'interp',
        bytes: const [0xFF, 0xFE],
        fromIdentity: 'voice-interpreter',
      ));
      await pumpEventQueue();

      expect(updates, isEmpty);
    });
  });

  group('reconnects', () {
    setUp(() async {
      await controller.start(url: 'wss://lk', token: 'tok', micOn: true);
      port.calls.clear();
    });

    test('reconnecting is reported', () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(const Reconnecting());
      await pumpEventQueue();

      expect(
          updates, [const Connection(InterpreterConnectionState.reconnecting)]);
    });

    test(
        'reconnected re-applies the mic restriction and restores the mic '
        'state, and is reported as ok', () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(const Reconnected());
      await pumpEventQueue();

      expect(port.calls,
          ['restrictMicTo(voice-interpreter)', 'setMicrophone(true)']);
      expect(updates, [const Connection(InterpreterConnectionState.ok)]);
    });

    test('reconnecting mutes the mic; reconnected restores it in order',
        () async {
      port.emit(const Reconnecting());
      await pumpEventQueue();
      expect(port.calls, ['setMicrophone(false)']);

      port.calls.clear();
      port.emit(const Reconnected());
      await pumpEventQueue();
      expect(port.calls,
          ['restrictMicTo(voice-interpreter)', 'setMicrophone(true)']);
    });

    test('a mic muted by the user before the reconnect stays muted after it',
        () async {
      await controller.setMic(false);
      port.calls.clear();

      port.emit(const Reconnecting());
      await pumpEventQueue();
      expect(port.calls, ['setMicrophone(false)']);

      port.calls.clear();
      port.emit(const Reconnected());
      await pumpEventQueue();
      // Restored to the remembered (muted) state, not force-unmuted.
      expect(port.calls,
          ['restrictMicTo(voice-interpreter)', 'setMicrophone(false)']);
    });

    test(
        'setMic during a reconnect only remembers the new state; it is '
        'applied once reconnected', () async {
      port.emit(const Reconnecting());
      await pumpEventQueue();
      port.calls.clear();

      // Started on, the gap muted it; the user taps to turn it back on
      // while still mid-reconnect.
      await controller.setMic(true);
      expect(port.calls, isEmpty);

      port.emit(const Reconnected());
      await pumpEventQueue();
      expect(port.calls,
          ['restrictMicTo(voice-interpreter)', 'setMicrophone(true)']);
    });
  });

  group('disconnect', () {
    setUp(() async {
      await controller.start(url: 'wss://lk', token: 'tok', micOn: true);
    });

    test('disconnected is reported as closed', () async {
      final updates = <RoomUpdate>[];
      controller.updates.listen(updates.add);

      port.emit(const Disconnected());
      await pumpEventQueue();

      expect(updates, [const Closed()]);
    });
  });

  group('dispose', () {
    test('disconnects the port and closes the update stream', () async {
      await controller.start(url: 'wss://lk', token: 'tok', micOn: true);

      var done = false;
      controller.updates.listen(null, onDone: () => done = true);

      await controller.dispose();
      await pumpEventQueue();

      expect(port.disconnected, isTrue);
      expect(done, isTrue);
    });
  });
}

/// Test-only helper so signal payloads can be built as plain maps instead of
/// hand-encoded byte literals.
List<int> parseToBytes(Map<String, Object?> json) =>
    utf8.encode(jsonEncode(json));
