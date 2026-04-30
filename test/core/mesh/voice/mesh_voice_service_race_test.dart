import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';

import 'mesh_voice_service_test_utils.dart';

void main() {
  group('MeshVoiceService _enterActive cancellation', () {
    test('hangup during accept() in-flight does not zombie-publish ActiveState',
        () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();
      final caller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));

      // Block engine.start so _enterActive parks mid-flight.
      h.fakeAudioEngine.startBlocker = Completer<void>();

      // Drive callee into IncomingState via inbound call_invite.
      const inviteCallId = 0x1234;
      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: caller,
        envelope: Envelope(
          version: 1, type: 'call_invite',
          convId: 'call-${inviteCallId.toRadixString(16)}',
          clientId: inviteCallId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': inviteCallId, 'codec_params': {}, 'datagram_seq_init': 1},
        ),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(h.svc.state, isA<IncomingState>());

      // Start accept (will park in engine.start because of blocker).
      final acceptFuture = h.svc.accept();
      await Future<void>.delayed(Duration.zero);

      // User mashes hangup while accept is still parked.
      await h.svc.hangup();
      expect(h.svc.state, isA<EndedState>());

      // Now release engine.start. _enterActive should observe gen mismatch
      // and bail without publishing ActiveState.
      h.fakeAudioEngine.startBlocker!.complete();
      await acceptFuture;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(h.svc.state, isA<EndedState>(),
          reason: 'state must remain Ended; in-flight _enterActive must NOT clobber');
    });

    test('remote call_end during accept() in-flight is honored', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();
      final caller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));

      h.fakeAudioEngine.startBlocker = Completer<void>();

      const inviteCallId = 0xABCD;
      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: caller,
        envelope: Envelope(
          version: 1, type: 'call_invite',
          convId: 'call-${inviteCallId.toRadixString(16)}',
          clientId: inviteCallId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': inviteCallId, 'codec_params': {}, 'datagram_seq_init': 1},
        ),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(h.svc.state, isA<IncomingState>());

      final acceptFuture = h.svc.accept();
      await Future<void>.delayed(Duration.zero);

      // Remote sends call_end.
      h.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: caller,
        envelope: Envelope(
          version: 1, type: 'call_end',
          convId: 'call-${inviteCallId.toRadixString(16)}',
          clientId: inviteCallId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': inviteCallId, 'reason': 'remoteHangup'},
        ),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(h.svc.state, isA<EndedState>());

      h.fakeAudioEngine.startBlocker!.complete();
      await acceptFuture;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(h.svc.state, isA<EndedState>());
    });
  });
}
