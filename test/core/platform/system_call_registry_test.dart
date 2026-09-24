// test/core/platform/system_call_registry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/call_kit.dart';
import 'package:taler_id_mobile/core/platform/system_call_registry.dart';

import 'system_call_fakes.dart';

const u1 = 'aaaaaaaa-1111-4111-8111-111111111111';
const u2 = 'bbbbbbbb-2222-4222-8222-222222222222';

void main() {
  late FakeCallKit kit;
  late FakeBridge bridge;
  late SystemCallRegistry reg;
  late List<SystemCallEvent> events;

  SystemCallRegistry build({
    bool enabled = true,
    List<String> uuids = const [u1, u2],
    Duration startTimeout = const Duration(milliseconds: 500),
  }) {
    final queue = List.of(uuids);
    final r = SystemCallRegistry(
      callKit: kit,
      bridge: bridge,
      enabled: enabled,
      startTimeout: startTimeout,
      answerTimeout: const Duration(milliseconds: 500),
      newUuid: () => queue.removeAt(0),
    )..attach();
    r.events.listen(events.add);
    return r;
  }

  setUp(() {
    kit = FakeCallKit();
    bridge = FakeBridge();
    events = [];
    reg = build();
  });

  tearDown(() => reg.detach());

  group('outgoing registration', () {
    test('confirmed start returns the uuid and makes it a conversation', () async {
      final uuid = await reg.startOutgoing(displayName: 'Alice', handle: 'conv-1');
      expect(uuid, u1);
      expect(bridge.prepared, 1, reason: 'category is set before CallKit activates');
      expect(kit.log, ['startCall:$u1:Alice:conv-1']);
      expect(bridge.lastManaged, [u1]);
      expect(reg.bindRoom(u1.toUpperCase(), 'call-room-1'), isTrue);
      expect(reg.isConversation('call-room-1'), isTrue);
      expect(reg.uuidForRoom('call-room-1'), u1);
    });

    test('bindRoom returns false once the call was ended while still starting', () async {
      kit.confirmStarts = false;
      final started = reg.startOutgoing(displayName: 'Alice', handle: 'h');
      await pumpEventQueue();
      await reg.endConversationByUuid(u1);
      expect(await started.timeout(const Duration(milliseconds: 200)), isNull);
      expect(reg.bindRoom(u1, 'call-room-1'), isFalse);
    });

    test('the bridge is told before CallKit: set-managed, prepare audio, start', () async {
      final calls = <String>[];
      bridge.onCall = calls.add;
      kit.onCall = calls.add;
      await reg.startOutgoing(displayName: 'Alice', handle: 'h');
      expect(calls, ['setManagedCalls', 'prepareCallAudio', 'startCall']);
    });

    test('an unconfirmed start falls back and a late start is ended', () async {
      kit.confirmStarts = false;
      expect(await reg.startOutgoing(displayName: 'Alice', handle: 'h'), isNull);
      expect(bridge.lastManaged, isEmpty);
      expect(bridge.managed, [
        [u1],
        [],
      ]);
      kit.emit(CallKitEvent.typeStart, u1);
      await pumpEventQueue();
      expect(kit.log, contains('endCall:$u1'));
    });

    test('a START that arrives after startCall returns still confirms in time', () async {
      kit.confirmStarts = false;
      final f = reg.startOutgoing(displayName: 'Alice', handle: 'h');
      await pumpEventQueue();
      kit.emit(CallKitEvent.typeStart, u1);
      expect(await f, u1);
    });

    test('an upper-case START confirmation still matches the lower-case uuid', () async {
      kit.confirmStarts = false;
      final f = reg.startOutgoing(displayName: 'Alice', handle: 'h');
      await pumpEventQueue();
      kit.emit(CallKitEvent.typeStart, u1.toUpperCase());
      expect(await f, u1);
    });

    test('prepareCallAudio failing returns null at once, without starting', () async {
      bridge.prepareCallAudioError = Exception('boom');
      await reg.detach();
      reg = build(startTimeout: const Duration(seconds: 10));
      final result = await reg
          .startOutgoing(displayName: 'Alice', handle: 'h')
          .timeout(const Duration(seconds: 1));
      expect(result, isNull);
      expect(bridge.lastManaged, isEmpty);
      expect(kit.log, isEmpty);
    });

    test('a failed initial sync returns null without touching CallKit, and frees a concurrent markConnected',
        () async {
      bridge.setManagedCallsError = Exception('boom');
      final f = reg.startOutgoing(displayName: 'Alice', handle: 'h', roomName: 'call-r1');
      final connected = reg.markConnected('call-r1');
      expect(await f, isNull);
      expect(kit.log, isEmpty);
      await connected.timeout(const Duration(seconds: 1));
      expect(kit.log, isNot(contains('setCallConnected:$u1')));
    });

    test('disabled registry never touches CallKit', () async {
      await reg.detach();
      reg = build(enabled: false);
      expect(await reg.startOutgoing(displayName: 'Alice', handle: 'h'), isNull);
      expect(kit.log, isEmpty);
    });

    test('startOutgoing before attach() is a no-op', () async {
      final fresh = SystemCallRegistry(
        callKit: kit,
        bridge: bridge,
        enabled: true,
        startTimeout: const Duration(milliseconds: 500),
        answerTimeout: const Duration(milliseconds: 500),
        newUuid: () => u1,
      ); // no .attach()
      expect(await fresh.startOutgoing(displayName: 'Alice', handle: 'h'), isNull);
      expect(kit.log, isEmpty);
    });
  });

  group('incoming', () {
    test('an accepted call with a room becomes a conversation', () async {
      kit.emit(CallKitEvent.typeAccept, u2, {
        'extra': {'roomName': 'call-r2'},
      });
      await pumpEventQueue();
      expect(reg.uuidForRoom('call-r2'), u2);
      expect(bridge.lastManaged, [u2]);
    });

    test('an upper-case ACCEPT is keyed by the lower-case uuid', () async {
      kit.emit(CallKitEvent.typeAccept, u2.toUpperCase(), {
        'extra': {'roomName': 'call-r2'},
      });
      await pumpEventQueue();
      expect(reg.uuidForRoom('call-r2'), u2);
      expect(bridge.lastManaged, [u2]);
    });

    test('group and mesh calls are not ours to manage', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {
        'extra': {'roomName': 'group-g1'},
      });
      kit.emit(CallKitEvent.typeAccept, u2, {
        'extra': {'roomName': 'r-mesh', 'kind': 'mesh_gc'},
      });
      await pumpEventQueue();
      expect(reg.hasConversations, isFalse);
    });

    test('adoptAnswered covers an accept the app did not hear', () async {
      await reg.adoptAnswered(uuid: u2.toUpperCase(), roomName: 'call-r2');
      expect(reg.uuidForRoom('call-r2'), u2);
      expect(bridge.lastManaged, [u2]);
    });

    test('adoptAnswered ignores a group call', () async {
      await reg.adoptAnswered(uuid: u2, roomName: 'group-g1');
      expect(reg.hasConversations, isFalse);
    });
  });

  group('markConnected', () {
    test('reports an outgoing call connected once', () async {
      await reg.startOutgoing(displayName: 'A', handle: 'h', roomName: 'call-r1');
      await reg.markConnected('call-r1');
      await reg.markConnected('call-r1');
      expect(kit.log.where((l) => l == 'setCallConnected:$u1'), hasLength(1));
    });

    test('leaves incoming calls alone — the answer connected them', () async {
      kit.emit(CallKitEvent.typeAccept, u2, {
        'extra': {'roomName': 'call-r2'},
      });
      await pumpEventQueue();
      await reg.markConnected('call-r2');
      expect(kit.log, isNot(contains('setCallConnected:$u2')));
    });

    test('waits for a pending start to be confirmed before reporting', () async {
      kit.confirmStarts = false;
      final f = reg.startOutgoing(displayName: 'Alice', handle: 'h', roomName: 'call-r1');
      final connected = reg.markConnected('call-r1');
      await pumpEventQueue();
      expect(
        kit.log,
        isNot(contains('setCallConnected:$u1')),
        reason: 'CallKit has not confirmed the call yet',
      );
      kit.emit(CallKitEvent.typeStart, u1);
      expect(await f, u1);
      await connected;
      expect(kit.log, contains('setCallConnected:$u1'));
    });

    test('two markConnected calls during a pending start report exactly once', () async {
      kit.confirmStarts = false;
      final f = reg.startOutgoing(displayName: 'Alice', handle: 'h', roomName: 'call-r1');
      final c1 = reg.markConnected('call-r1');
      final c2 = reg.markConnected('call-r1');
      await pumpEventQueue();
      kit.emit(CallKitEvent.typeStart, u1);
      expect(await f, u1);
      await c1;
      await c2;
      expect(kit.log.where((l) => l == 'setCallConnected:$u1'), hasLength(1));
    });

    test('markConnected during a start CallKit never confirms returns without reporting', () async {
      kit.confirmStarts = false;
      final f = reg.startOutgoing(displayName: 'Alice', handle: 'h', roomName: 'call-r1');
      final connected = reg.markConnected('call-r1');
      expect(await f, isNull);
      await connected.timeout(const Duration(seconds: 1));
      expect(kit.log, isNot(contains('setCallConnected:$u1')));
    });
  });

  group('ending', () {
    Future<void> conversation(String uuid, String room) async {
      kit.emit(CallKitEvent.typeAccept, uuid, {
        'extra': {'roomName': room},
      });
      await pumpEventQueue();
    }

    test('an end from the system reaches the app once', () async {
      await conversation(u1, 'call-r1');
      kit.emit(CallKitEvent.typeEnded, u1);
      await pumpEventQueue();
      expect(events.whereType<SystemCallEndedBySystem>().single.roomName, 'call-r1');
      expect(reg.isConversation('call-r1'), isFalse);
      expect(bridge.lastManaged, isEmpty);
    });

    test('DECLINE on a conversation is a system end too', () async {
      await conversation(u1, 'call-r1');
      kit.emit(CallKitEvent.typeDecline, u1);
      await pumpEventQueue();
      expect(events.whereType<SystemCallEndedBySystem>().single.roomName, 'call-r1');
      expect(reg.isConversation('call-r1'), isFalse);
    });

    test('TIMEOUT on a conversation is a system end too', () async {
      await conversation(u1, 'call-r1');
      kit.emit(CallKitEvent.typeTimeout, u1);
      await pumpEventQueue();
      expect(events.whereType<SystemCallEndedBySystem>().single.roomName, 'call-r1');
      expect(reg.isConversation('call-r1'), isFalse);
    });

    test('a second ENDED does not produce a second event', () async {
      await conversation(u1, 'call-r1');
      kit.emit(CallKitEvent.typeEnded, u1);
      kit.emit(CallKitEvent.typeEnded, u1);
      await pumpEventQueue();
      expect(events.whereType<SystemCallEndedBySystem>(), hasLength(1));
    });

    test('a declined second call does not touch the conversation', () async {
      await conversation(u1, 'call-r1');
      kit.emit(CallKitEvent.typeDecline, u2);
      kit.emit(CallKitEvent.typeEnded, u2);
      await pumpEventQueue();
      expect(events, isEmpty);
      expect(reg.isConversation('call-r1'), isTrue);
    });

    test('our own hang-up is not reported back as a system end', () async {
      await conversation(u1, 'call-r1');
      await reg.endConversation('call-r1');
      kit.emit(CallKitEvent.typeEnded, u1);
      await pumpEventQueue();
      expect(kit.log, contains('endCall:$u1'));
      expect(events, isEmpty);
    });

    test('endConversationByUuid and endAllConversations end only ours', () async {
      await conversation(u1, 'call-r1');
      await conversation(u2, 'call-r2');
      await reg.endConversationByUuid(u1.toUpperCase());
      expect(kit.log, contains('endCall:$u1'));
      await reg.endAllConversations();
      expect(kit.log, contains('endCall:$u2'));
      expect(kit.log, isNot(contains('endAllCalls')));
      expect(reg.hasConversations, isFalse);
    });

    test('a failed endCall does not stop endAllConversations from ending the rest', () async {
      await conversation(u1, 'call-r1');
      await conversation(u2, 'call-r2');
      kit.endCallError = Exception('boom');
      await reg.endAllConversations();
      expect(kit.log, containsAll(['endCall:$u1', 'endCall:$u2']));
      expect(reg.hasConversations, isFalse);
    });

    test('hanging up before CallKit confirms the start stops the wait', () async {
      kit.confirmStarts = false;
      final started = reg.startOutgoing(displayName: 'A', handle: 'h', roomName: 'call-r1');
      await pumpEventQueue();
      final connected = reg.markConnected('call-r1');
      await reg.endConversation('call-r1');
      // Well inside the harness startTimeout: the wait ended with the hang-up.
      expect(await started.timeout(const Duration(milliseconds: 200)), isNull);
      // markConnected was waiting on the same pending start; the hang-up frees
      // it too, without ever reaching CallKit — exercises its identity check.
      await connected.timeout(const Duration(milliseconds: 200));
      expect(kit.log, isNot(contains('setCallConnected:$u1')));
      kit.emit(CallKitEvent.typeStart, u1); // CallKit processes the start late
      await pumpEventQueue();
      expect(kit.log.where((l) => l == 'endCall:$u1'), hasLength(1),
          reason: 'ended once by the hang-up, not again as an abandoned start');
    });

    test('a system end while still starting completes the pending start promptly', () async {
      kit.confirmStarts = false;
      final started = reg.startOutgoing(displayName: 'A', handle: 'h');
      await pumpEventQueue();
      kit.emit(CallKitEvent.typeEnded, u1);
      expect(await started.timeout(const Duration(milliseconds: 200)), isNull);
    });
  });

  group('dismissRinging', () {
    test('ends ringing calls, keeps conversations and other apps\' calls', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {
        'extra': {'roomName': 'call-r1'},
      });
      await pumpEventQueue();
      kit.active = [
        {
          'id': u1,
          'extra': {'roomName': 'call-r1'},
        },
        {
          'id': u2,
          'extra': {'roomName': 'call-r2'},
        },
        {'id': 'AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA'}, // WhatsApp: no payload
      ];
      await reg.dismissRinging();
      expect(kit.log.where((l) => l.startsWith('endCall:')), ['endCall:$u2']);
    });

    test('a registered conversation listed under an upper-case id is not ended', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {
        'extra': {'roomName': 'call-r1'},
      });
      await pumpEventQueue();
      kit.active = [
        {
          'id': u1.toUpperCase(),
          'extra': {'roomName': 'call-r1'},
        },
      ];
      await reg.dismissRinging();
      expect(kit.log, isEmpty);
    });

    test('an answered call-screen conversation Dart has not registered yet is left alone', () async {
      kit.active = [
        {
          'id': u1,
          'extra': {'roomName': 'call-r1'},
          'isAccepted': true,
        },
      ];
      await reg.dismissRinging();
      expect(kit.log, isEmpty);
    });

    test('an answered group/mesh call stays dismissable', () async {
      kit.active = [
        {
          'id': u1,
          'extra': {'roomName': 'group-g1'},
          'isAccepted': true,
        },
        {
          'id': u2,
          'extra': {'roomName': 'r-mesh', 'kind': 'mesh_gc'},
          'accepted': true,
        },
      ];
      await reg.dismissRinging();
      expect(kit.log.where((l) => l.startsWith('endCall:')), containsAll(['endCall:$u1', 'endCall:$u2']));
    });

    test('activeCalls failing leaves dismissRinging silent, not throwing', () async {
      kit.activeCallsError = Exception('boom');
      await reg.dismissRinging();
      expect(kit.log, isEmpty);
    });

    test('a failed endCall does not stop dismissRinging from continuing', () async {
      kit.active = [
        {
          'id': u1,
          'extra': {'roomName': 'call-r1'},
        },
        {
          'id': u2,
          'extra': {'roomName': 'call-r2'},
        },
      ];
      kit.endCallError = Exception('boom');
      await reg.dismissRinging();
      expect(kit.log, ['endCall:$u1', 'endCall:$u2']);
    });

    test('disabled registry: the old endAllCalls', () async {
      await reg.detach();
      reg = build(enabled: false);
      await reg.dismissRinging();
      expect(kit.log, ['endAllCalls']);
    });
  });

  group('endRingingForRoom', () {
    test('ends the room\'s ringing call', () async {
      kit.active = [
        {
          'id': u2,
          'extra': {'roomName': u2},
        },
      ];
      expect(await reg.endRingingForRoom(u2), isFalse);
      expect(kit.log, ['endCall:$u2']);
    });

    test('matches a realistic call-<uuid> room name', () async {
      kit.active = [
        {
          'id': u2,
          'extra': {'roomName': 'call-$u2'},
        },
      ];
      expect(await reg.endRingingForRoom('call-$u2'), isFalse);
      expect(kit.log, ['endCall:$u2']);
    });

    test('an upper-case raw id is matched too', () async {
      kit.active = [
        {
          'id': u2.toUpperCase(),
          'extra': {'roomName': u2},
        },
      ];
      expect(await reg.endRingingForRoom(u2), isFalse);
      expect(kit.log, ['endCall:$u2']);
    });

    test('matches by extra.roomName when the id is not derived from the room (VoIP fallback id)', () async {
      kit.active = [
        {
          'id': u1,
          'extra': {'roomName': 'custom-room-xyz'},
        },
      ];
      expect(await reg.endRingingForRoom('custom-room-xyz'), isFalse);
      expect(kit.log, ['endCall:$u1']);
    });

    test('leaves a conversation alone and says so', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {
        'extra': {'roomName': u1},
      });
      await pumpEventQueue();
      expect(await reg.endRingingForRoom(u1), isTrue);
      expect(kit.log, isEmpty);
    });

    test(
        'a call CallKit reports answered counts as a conversation — '
        'covers the moment before Dart registers the accept', () async {
      kit.active = [
        {
          'id': u2,
          'extra': {'roomName': u2},
          'isAccepted': true,
        },
      ];
      expect(await reg.endRingingForRoom(u2), isTrue);
      expect(kit.log, isEmpty);
    });

    test('accepted (not isAccepted) also counts as a conversation', () async {
      kit.active = [
        {
          'id': u2,
          'extra': {'roomName': u2},
          'accepted': true,
        },
      ];
      expect(await reg.endRingingForRoom(u2), isTrue);
      expect(kit.log, isEmpty);
    });

    test('activeCalls failing returns false, not throwing', () async {
      kit.activeCallsError = Exception('boom');
      expect(await reg.endRingingForRoom(u2), isFalse);
    });

    test('a failed endCall still returns false, not throwing', () async {
      kit.active = [
        {
          'id': u2,
          'extra': {'roomName': u2},
        },
      ];
      kit.endCallError = Exception('boom');
      expect(await reg.endRingingForRoom(u2), isFalse);
      expect(kit.log, ['endCall:$u2']);
    });

    test('disabled registry: the old endAllCalls', () async {
      await reg.detach();
      reg = build(enabled: false);
      expect(await reg.endRingingForRoom(u2), isFalse);
      expect(kit.log, ['endAllCalls']);
    });
  });

  group('hold and auto-resume', () {
    Future<void> conversation(String uuid, String room) async {
      kit.emit(CallKitEvent.typeAccept, uuid, {
        'extra': {'roomName': room},
      });
      await pumpEventQueue();
    }

    test('call waiting holds the call; the end of the other call resumes it', () async {
      await conversation(u1, 'call-r1');
      kit.emit(CallKitEvent.typeToggleHold, u1, {'isOnHold': true});
      kit.emit(CallKitEvent.typeToggleHold, u1, {'isOnHold': true}); // echo
      await pumpEventQueue();
      expect(events.whereType<SystemCallHeld>().single.bySystem, isTrue);
      expect(reg.isHeldBySystem('call-r1'), isTrue);

      bridge.otherCallsGone();
      await pumpEventQueue();
      expect(kit.log, contains('setHeld:$u1:false'));

      kit.emit(CallKitEvent.typeToggleHold, u1, {'isOnHold': false});
      await pumpEventQueue();
      expect(events.last, isA<SystemCallResumed>());
      expect(reg.isHeldBySystem('call-r1'), isFalse);
    });

    test('no auto-resume while another conversation is active', () async {
      await conversation(u1, 'call-r1');
      await conversation(u2, 'call-r2');
      kit.emit(CallKitEvent.typeToggleHold, u1, {'isOnHold': true});
      await pumpEventQueue();
      bridge.otherCallsGone();
      await pumpEventQueue();
      expect(kit.log, isNot(contains('setHeld:$u1:false')));
    });

    test('a line-switch hold is ours and never auto-resumed', () async {
      await conversation(u1, 'call-r1');
      await reg.holdForLineSwitch('call-r1', true);
      kit.emit(CallKitEvent.typeToggleHold, u1, {'isOnHold': true});
      await pumpEventQueue();
      expect(events.whereType<SystemCallHeld>().single.bySystem, isFalse);
      bridge.otherCallsGone();
      await pumpEventQueue();
      expect(kit.log.where((l) => l == 'setHeld:$u1:false'), isEmpty);
    });

    test('resume() is the overlay button', () async {
      await conversation(u1, 'call-r1');
      await reg.resume('call-r1');
      expect(kit.log, contains('setHeld:$u1:false'));
    });
  });

  group('mute', () {
    test('the system mute button reaches the app', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {
        'extra': {'roomName': 'call-r1'},
      });
      await pumpEventQueue();
      kit.emit(CallKitEvent.typeToggleMute, u1, {'isMuted': true});
      await pumpEventQueue();
      final e = events.whereType<SystemCallMuteChanged>().single;
      expect(e.muted, isTrue);
      expect(e.roomName, 'call-r1');
    });

    test('our mute is mirrored into CallKit', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {
        'extra': {'roomName': 'call-r1'},
      });
      await pumpEventQueue();
      await reg.setMuted('call-r1', true);
      expect(kit.log, contains('setMuted:$u1:true'));
    });
  });

  group('answerRinging', () {
    test('answers through CallKit and reports the accept', () async {
      final answered = reg.answerRinging(u2);
      await pumpEventQueue();
      expect(kit.log, contains('setCallConnected:$u2'));
      kit.emit(CallKitEvent.typeAccept, u2, {
        'extra': {'roomName': u2},
      });
      expect(await answered, isTrue);
    });

    test('false when CallKit stays silent — the dialog takes the old path', () async {
      expect(await reg.answerRinging(u2), isFalse);
    });
  });

  group('instance', () {
    test('the off-iPhone singleton works without a native channel', () async {
      SystemCallRegistry.debugInstance = null;
      addTearDown(() => SystemCallRegistry.debugInstance = null);
      final instance = SystemCallRegistry.instance;
      expect(instance.enabled, isFalse);
      expect(await instance.startOutgoing(displayName: 'Alice', handle: 'h'), isNull);
    });
  });
}
