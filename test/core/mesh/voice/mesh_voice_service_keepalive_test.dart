import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/transport/transport_preference.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_frame.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';

import 'mesh_voice_service_test_utils.dart';

void main() {
  group('MeshVoiceService keepalive + timeout', () {
    test('3s no inbound datagrams → ENDED(noKeepalive)', () {
      fakeAsync((async) {
        final h = MeshVoiceTestHarness.build();
        h.svc.start();
        final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
        // ignore: unawaited_futures
        h.svc.invite(callee).then((callId) {
          h.fakeMessaging.emitInbound(InboundEnvelope(
            fromUserPk: callee,
            envelope: Envelope(
              version: 1, type: 'call_accept',
              convId: 'call-${callId.toRadixString(16)}',
              clientId: callId.toRadixString(16),
              text: '', sentAt: DateTime.now().toUtc(),
              extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 99},
            ),
          ));
        });
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 100));
        expect(h.svc.state, isA<ActiveState>());

        async.elapse(const Duration(seconds: 4));
        expect(h.svc.state, isA<EndedState>());
        expect((h.svc.state as EndedState).reason, EndReason.noKeepalive);
      });
    });

    test('inbound datagram resets the timeout', () {
      fakeAsync((async) {
        final h = MeshVoiceTestHarness.build();
        h.svc.start();
        final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
        // ignore: unawaited_futures
        h.svc.invite(callee).then((callId) {
          h.fakeMessaging.emitInbound(InboundEnvelope(
            fromUserPk: callee,
            envelope: Envelope(
              version: 1, type: 'call_accept',
              convId: 'call-${callId.toRadixString(16)}',
              clientId: callId.toRadixString(16),
              text: '', sentAt: DateTime.now().toUtc(),
              extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 99},
            ),
          ));
        });
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 100));
        final activeCallId = (h.svc.state as ActiveState).callId;

        // Tick liveness every 2s — never reaches 3s without a datagram.
        for (var i = 0; i < 5; i++) {
          async.elapse(const Duration(seconds: 2));
          // Fake an inbound datagram (just header — content will fail to decrypt
          // but liveness is tracked at receive level, before decrypt).
          final frame = MeshVoiceFrame(
            type: MeshVoiceFrameType.audio,
            callId: activeCallId,
            seq: i + 1,
            ciphertext: Uint8List.fromList([1, 2, 3]),
          );
          h.fakeTransport.emitDatagram(InboundDatagram(
            srcPeer: callee,
            bytes: frame.encode(),
            via: TransportId.bonjour,
          ));
          async.flushMicrotasks();
        }

        expect(h.svc.state, isA<ActiveState>(),
            reason: 'datagrams every 2s keep the call alive');
      });
    });

    test('hangup() emits call_end and transitions to ENDED', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();
      final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      final callId = await h.svc.invite(callee);
      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: callee,
        envelope: Envelope(
          version: 1, type: 'call_accept',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 99},
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      h.fakeMessaging.sentEnvelopes.clear();

      await h.svc.hangup();

      expect(h.svc.state, isA<EndedState>());
      expect((h.svc.state as EndedState).reason, EndReason.userHangup);
      // call_end envelope was sent.
      final ends = h.fakeMessaging.sentEnvelopes.where((s) => s.envelope.type == 'call_end');
      expect(ends, hasLength(1));
    });
  });
}
