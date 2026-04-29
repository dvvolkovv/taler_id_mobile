import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';

import 'mesh_voice_service_test_utils.dart';

void main() {
  group('MeshVoiceService callee path', () {
    test('inbound call_invite transitions to IncomingState', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();

      final caller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));
      const callId = 0x1234;
      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: caller,
        envelope: Envelope(
          version: 1,
          type: 'call_invite',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {
            'call_id': callId,
            'codec_params': {'audio': 'opus', 'rate': 16000, 'channels': 1, 'frame_ms': 20, 'bitrate': 24000, 'fec': false},
            'datagram_seq_init': 1,
          },
        ),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(h.svc.state, isA<IncomingState>());
      expect((h.svc.state as IncomingState).callerDevicePk, caller);
      expect((h.svc.state as IncomingState).callId, callId);
    });

    test('accept() sends call_accept and transitions to ConnectingState', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();

      final caller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));
      const callId = 0x1234;
      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: caller,
        envelope: Envelope(
          version: 1, type: 'call_invite',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 1},
        ),
      ));
      await Future<void>.delayed(Duration.zero);
      h.fakeMessaging.sentEnvelopes.clear();

      await h.svc.accept();
      expect(h.svc.state, isA<ConnectingState>());
      expect(h.fakeMessaging.sentEnvelopes, hasLength(1));
      expect(h.fakeMessaging.sentEnvelopes.first.envelope.type, 'call_accept');
    });

    test('reject() sends call_reject and transitions to EndedState', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();

      final caller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));
      const callId = 0x1234;
      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: caller,
        envelope: Envelope(
          version: 1, type: 'call_invite',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 1},
        ),
      ));
      await Future<void>.delayed(Duration.zero);
      h.fakeMessaging.sentEnvelopes.clear();

      await h.svc.reject();
      expect(h.svc.state, isA<EndedState>());
      final rejects = h.fakeMessaging.sentEnvelopes
          .where((s) => s.envelope.type == 'call_reject');
      expect(rejects, hasLength(1));
      expect(rejects.first.toUserPk, caller);
    });

    test('busy: incoming invite while in non-Idle state replies with call_reject{busy}', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();

      // First caller invites + we accept → ConnectingState.
      final firstCaller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));
      const firstCallId = 0x1234;
      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: firstCaller,
        envelope: Envelope(
          version: 1, type: 'call_invite',
          convId: 'call-${firstCallId.toRadixString(16)}',
          clientId: firstCallId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': firstCallId, 'codec_params': {}, 'datagram_seq_init': 1},
        ),
      ));
      await Future<void>.delayed(Duration.zero);
      await h.svc.accept(); // → ConnectingState

      h.fakeMessaging.sentEnvelopes.clear();

      // Second caller invites while we're busy.
      final secondCaller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      const secondCallId = 0x5678;
      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: secondCaller,
        envelope: Envelope(
          version: 1, type: 'call_invite',
          convId: 'call-${secondCallId.toRadixString(16)}',
          clientId: secondCallId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': secondCallId, 'codec_params': {}, 'datagram_seq_init': 1},
        ),
      ));
      await Future<void>.delayed(Duration.zero);

      // Expect a call_reject{busy} sent back to second caller.
      final rejects = h.fakeMessaging.sentEnvelopes
          .where((s) => s.envelope.type == 'call_reject');
      expect(rejects, hasLength(1));
      expect(rejects.first.toUserPk, secondCaller);
      expect(rejects.first.envelope.extra!['reason'], 'busy');
    });
  });
}
