import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';

import 'mesh_voice_service_test_utils.dart';

void main() {
  group('MeshVoiceService ACTIVE state', () {
    test('caller transitions to Active after call_accept and starts audio engine', () async {
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

      expect(h.svc.state, isA<ActiveState>());
      expect(h.fakeAudioEngine.started, isTrue);
    });

    test('outbound audio frames are sent as datagrams', () async {
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

      // Audio engine emits a "encoded Opus" frame — service must wrap + send.
      h.fakeAudioEngine.emitOutbound(Uint8List.fromList(List<int>.generate(40, (i) => i)));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(h.fakeTransport.sentDatagrams, hasLength(1));
      final (sentPeer, sentBytes) = h.fakeTransport.sentDatagrams.first;
      expect(sentPeer, callee);
      expect(sentBytes.length, greaterThanOrEqualTo(13 + 40),
          reason: 'frame includes 13-byte header + ciphertext (≥ plaintext length)');
    });
  });
}
