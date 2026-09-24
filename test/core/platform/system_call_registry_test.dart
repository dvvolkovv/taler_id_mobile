import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/call_kit.dart';
import 'package:taler_id_mobile/core/platform/system_call_registry.dart';

import 'system_call_fakes.dart';

const u1 = '11111111-1111-4111-8111-111111111111';
const u2 = '22222222-2222-4222-8222-222222222222';

void main() {
  late FakeCallKit kit;
  late FakeBridge bridge;
  late SystemCallRegistry reg;
  late List<SystemCallEvent> events;

  SystemCallRegistry build({bool enabled = true, List<String> uuids = const [u1, u2]}) {
    final queue = List.of(uuids);
    final r = SystemCallRegistry(
      callKit: kit,
      bridge: bridge,
      enabled: enabled,
      startTimeout: const Duration(milliseconds: 50),
      answerTimeout: const Duration(milliseconds: 50),
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

    test('an unconfirmed start falls back and a late start is ended', () async {
      kit.confirmStarts = false;
      expect(await reg.startOutgoing(displayName: 'Alice', handle: 'h'), isNull);
      expect(bridge.lastManaged, isEmpty);
      kit.emit(CallKitEvent.typeStart, u1);
      await pumpEventQueue();
      expect(kit.log, contains('endCall:$u1'));
    });

    test('disabled registry never touches CallKit', () async {
      await reg.detach();
      reg = build(enabled: false);
      expect(await reg.startOutgoing(displayName: 'Alice', handle: 'h'), isNull);
      expect(kit.log, isEmpty);
    });
  });

  group('incoming', () {
    test('an accepted call with a room becomes a conversation', () async {
      kit.emit(CallKitEvent.typeAccept, u2, {'extra': {'roomName': 'call-r2'}});
      await pumpEventQueue();
      expect(reg.uuidForRoom('call-r2'), u2);
      expect(bridge.lastManaged, [u2]);
    });

    test('group and mesh calls are not ours to manage', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {'extra': {'roomName': 'group-g1'}});
      kit.emit(CallKitEvent.typeAccept, u2,
          {'extra': {'roomName': 'r-mesh', 'kind': 'mesh_gc'}});
      await pumpEventQueue();
      expect(reg.hasConversations, isFalse);
    });

    test('adoptAnswered covers an accept the app did not hear', () async {
      await reg.adoptAnswered(uuid: u2.toUpperCase(), roomName: 'call-r2');
      expect(reg.uuidForRoom('call-r2'), u2);
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
      kit.emit(CallKitEvent.typeAccept, u2, {'extra': {'roomName': 'call-r2'}});
      await pumpEventQueue();
      await reg.markConnected('call-r2');
      expect(kit.log, isNot(contains('setCallConnected:$u2')));
    });
  });
}
