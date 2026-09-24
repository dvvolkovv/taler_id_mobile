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
      reg.bindRoom(u1, 'call-room-1');
      expect(reg.isConversation('call-room-1'), isTrue);
      expect(reg.uuidForRoom('call-room-1'), u1);
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
  });
}
