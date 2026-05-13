import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_service.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';

class _MockMessaging extends Mock implements MeshMessagingService {}

class _MockTransport extends Mock implements MeshTransport {}

class _FakeEnvelope extends Fake implements Envelope {}

class _FakePeerId extends Fake implements PeerId {}

void main() {
  late _MockMessaging messaging;
  late StreamController<InboundEnvelope> inboundCtrl;
  late GroupMeshCallService svc;

  // 32-byte devicePks, byte-uniform for easy lex comparison.
  final myPk = Uint8List.fromList(List<int>.generate(32, (_) => 0xAA));
  final peerBPk = Uint8List.fromList(List<int>.generate(32, (_) => 0xBB));
  final peerCPk = Uint8List.fromList(List<int>.generate(32, (_) => 0xCC));

  String hex(Uint8List b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  setUpAll(() {
    registerFallbackValue(_FakeEnvelope());
    registerFallbackValue(_FakePeerId());
  });

  setUp(() {
    messaging = _MockMessaging();
    inboundCtrl = StreamController<InboundEnvelope>.broadcast();
    when(() => messaging.inbound).thenAnswer((_) => inboundCtrl.stream);
    when(() => messaging.sendEnvelope(
          toUserPk: any(named: 'toUserPk'),
          envelope: any(named: 'envelope'),
        )).thenAnswer((_) async {});
    when(() => messaging.datagramCiphersFor(any()))
        .thenAnswer((_) async => null);

    final transport = _MockTransport();
    when(() => transport.inboundDatagrams)
        .thenAnswer((_) => const Stream.empty());

    svc = GroupMeshCallService(
      messaging: messaging,
      transport: transport,
      myDevicePk: myPk,
      lobbyTimeout: const Duration(milliseconds: 200),
    );
  });

  tearDown(() async {
    await svc.dispose();
    await inboundCtrl.close();
  });

  test(
      'start() from Idle transitions through Inviting → Lobby and fans out invites',
      () async {
    expect(svc.state, isA<GMCIdle>());

    await svc.start(invitees: {
      hex(peerBPk): 'userB',
      hex(peerCPk): 'userC',
    });

    expect(svc.state, isA<GMCLobby>());
    final lobby = svc.state as GMCLobby;
    expect(lobby.roster.where((p) => p.status == GMCStatus.calling).length, 2);

    verify(() => messaging.sendEnvelope(
          toUserPk: any(named: 'toUserPk'),
          envelope: any(
              named: 'envelope',
              that: predicate<Envelope>(
                  (e) => e.type == MeshGcEnvelopeType.invite)),
        )).called(2);
  });

  test('accept envelope from sole invitee transitions to Active', () async {
    await svc.start(invitees: {hex(peerBPk): 'userB'});

    inboundCtrl.add(InboundEnvelope(
      fromUserPk: PeerId(peerBPk),
      envelope: Envelope(
        version: 1,
        type: MeshGcEnvelopeType.accept,
        convId: (svc.state as GMCLobby).roomId,
        clientId: 'c',
        text: '',
        sentAt: DateTime.now().toUtc(),
        extra: {
          'roomId': (svc.state as GMCLobby).roomId,
          'devicePk': hex(peerBPk),
        },
      ),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(svc.state, isA<GMCActive>());
  });

  test('decline envelope from sole invitee → Ended(allDeclined)', () async {
    await svc.start(invitees: {hex(peerBPk): 'userB'});

    inboundCtrl.add(InboundEnvelope(
      fromUserPk: PeerId(peerBPk),
      envelope: Envelope(
        version: 1,
        type: MeshGcEnvelopeType.decline,
        convId: (svc.state as GMCLobby).roomId,
        clientId: 'c',
        text: '',
        sentAt: DateTime.now().toUtc(),
        extra: {
          'roomId': (svc.state as GMCLobby).roomId,
          'devicePk': hex(peerBPk),
        },
      ),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(svc.state, isA<GMCEnded>());
    expect((svc.state as GMCEnded).reason, GMCEndReason.allDeclined);
  });

  test('lobby timeout with no accepts → Ended(noAnswer)', () async {
    await svc.start(invitees: {hex(peerBPk): 'userB'});
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(svc.state, isA<GMCEnded>());
    expect((svc.state as GMCEnded).reason, GMCEndReason.noAnswer);
  });

  test('hard cap rejects start with >4 invitees', () async {
    final tooMany = <String, String>{
      for (var i = 0; i < 5; i++)
        hex(Uint8List.fromList(List<int>.generate(32, (_) => i + 1))): 'u$i',
    };
    await expectLater(svc.start(invitees: tooMany), throwsA(isA<StateError>()));
  });

  test('inbound mesh_gc_invite is forwarded to incomingInviteStream', () async {
    final received = <InboundEnvelope>[];
    final sub = svc.incomingInviteStream.listen(received.add);
    inboundCtrl.add(InboundEnvelope(
      fromUserPk: PeerId(peerBPk),
      envelope: Envelope(
        version: 1,
        type: MeshGcEnvelopeType.invite,
        convId: 'roomXYZ',
        clientId: 'c',
        text: '',
        sentAt: DateTime.now().toUtc(),
        extra: {
          'roomId': 'roomXYZ',
          'hostDevicePk': hex(peerBPk),
          'participants': [hex(myPk), hex(peerBPk)],
        },
      ),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(received.length, 1);
    expect(received.first.envelope.type, MeshGcEnvelopeType.invite);
    await sub.cancel();
  });

  test('leave() during lobby cancels timer before fanout, no double Ended',
      () async {
    final endedReasons = <GMCEndReason>[];
    final sub = svc.stateStream.listen((s) {
      if (s is GMCEnded) endedReasons.add(s.reason);
    });

    await svc.start(invitees: {hex(peerBPk): 'userB'});
    await svc.leave();

    // Wait past the original lobby timeout to confirm timer did not fire.
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(endedReasons, [GMCEndReason.userHangup],
        reason: 'exactly one Ended emission expected — userHangup');

    await sub.cancel();
  });

  group('Noise role assignment', () {
    test('peer with lexicographically smaller devicePk initiates', () {
      final smaller =
          Uint8List.fromList(List<int>.generate(32, (_) => 0xAA));
      final larger =
          Uint8List.fromList(List<int>.generate(32, (_) => 0xBB));
      expect(GroupMeshCallService.shouldInitiateNoise(smaller, larger), isTrue);
      expect(
          GroupMeshCallService.shouldInitiateNoise(larger, smaller), isFalse);
    });

    test('equal devicePk byte-strings returns false (degenerate self-pair)',
        () {
      final pk = Uint8List.fromList(List<int>.generate(32, (_) => 0x42));
      expect(GroupMeshCallService.shouldInitiateNoise(pk, pk), isFalse);
    });

    test('first-byte tie broken by later bytes', () {
      final a = Uint8List(32)..[0] = 0x10..[31] = 0x05;
      final b = Uint8List(32)..[0] = 0x10..[31] = 0x06;
      expect(GroupMeshCallService.shouldInitiateNoise(a, b), isTrue);
      expect(GroupMeshCallService.shouldInitiateNoise(b, a), isFalse);
    });
  });
}
