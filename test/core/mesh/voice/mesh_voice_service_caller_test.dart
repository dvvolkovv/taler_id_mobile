import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';

import 'mesh_voice_service_test_utils.dart';

void main() {
  group('MeshVoiceService caller path', () {
    test('invite() emits InvitingState and sends call_invite envelope', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();

      final calleePk = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      final callId = await h.svc.invite(calleePk);

      expect(h.svc.state, isA<InvitingState>());
      final inv = h.svc.state as InvitingState;
      expect(inv.calleeDevicePk, calleePk);
      expect(inv.callId, callId);

      // Outbound envelope was issued via FakeMessaging.
      expect(h.fakeMessaging.sentEnvelopes, hasLength(1));
      final sent = h.fakeMessaging.sentEnvelopes.first;
      expect(sent.toUserPk, calleePk);
      expect(sent.envelope.type, 'call_invite');
      expect(sent.envelope.extra, isNotNull);
      expect(sent.envelope.extra!['call_id'], callId);
    });

    test('on call_accept envelope, transitions to ActiveState', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();
      final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      final callId = await h.svc.invite(callee);

      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: callee,
        envelope: Envelope(
          version: 1,
          type: 'call_accept',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId},
        ),
      ));
      // Allow async _enterActive (which awaits datagramCiphersFor + audio start) to run.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(h.svc.state, isA<ActiveState>());
    });

    test('on call_reject envelope, transitions to EndedState(rejectedByCallee)', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();
      final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      final callId = await h.svc.invite(callee);

      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: callee,
        envelope: Envelope(
          version: 1,
          type: 'call_reject',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'reason': 'declined'},
        ),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(h.svc.state, isA<EndedState>());
      expect((h.svc.state as EndedState).reason, EndReason.rejectedByCallee);
    });

    test('30s no response → invite timeout', () {
      fakeAsync((async) {
        final h = MeshVoiceTestHarness.build();
        h.svc.start();
        final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 1)));
        // ignore: unawaited_futures
        h.svc.invite(callee);
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 31));
        expect(h.svc.state, isA<EndedState>());
        expect((h.svc.state as EndedState).reason, EndReason.inviteTimeout);
      });
    });
  });
}
