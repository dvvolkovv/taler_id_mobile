import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';
import 'package:taler_id_mobile/core/voice/mesh_voice_ui_coordinator.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_entry.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_repository.dart';

import '../mesh/voice/mesh_voice_service_test_utils.dart';

class _NoopRepo implements MeshCallHistoryRepository {
  final entries = <MeshCallHistoryEntry>[];
  @override Future<void> add(MeshCallHistoryEntry e) async => entries.add(e);
  @override Future<void> deleteById(int callId) async {}
  @override Future<List<MeshCallHistoryEntry>> getAll() async =>
      List.of(entries);
  @override Stream<List<MeshCallHistoryEntry>> watch() =>
      const Stream.empty();
}

class _NoopNav implements MeshNavigator {
  @override Future<T?> pushScreen<T>(Widget s) async => null;
  @override Future<void> showSheet(Widget s) async {}
  @override void popSheet() {}
  @override void popScreen() {}
  @override void showSnackbar(String m) {}
}

PeerId _peer(int seed) =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i + seed)));

void main() {
  test('full flow: invite → accept → ACTIVE → hangup → history written on receiver',
      () async {
    final aliceHarness = MeshVoiceTestHarness.build();
    final bobHarness = MeshVoiceTestHarness.build();

    aliceHarness.svc.start();
    bobHarness.svc.start();

    // Bridge: drain sentEnvelopes from each fake messaging into the other's
    // inbound stream, simulating peer delivery.
    final pump = Timer.periodic(const Duration(milliseconds: 5), (t) {
      while (aliceHarness.fakeMessaging.sentEnvelopes.isNotEmpty) {
        final e = aliceHarness.fakeMessaging.sentEnvelopes.removeAt(0);
        bobHarness.fakeMessaging.emitInbound(InboundEnvelope(
            fromUserPk: _peer(1), envelope: e.envelope));
      }
      while (bobHarness.fakeMessaging.sentEnvelopes.isNotEmpty) {
        final e = bobHarness.fakeMessaging.sentEnvelopes.removeAt(0);
        aliceHarness.fakeMessaging.emitInbound(InboundEnvelope(
            fromUserPk: _peer(2), envelope: e.envelope));
      }
    });
    addTearDown(pump.cancel);

    final aliceRepo = _NoopRepo();
    final bobRepo = _NoopRepo();
    final aliceCoord = MeshVoiceUiCoordinator(
      stateStream: aliceHarness.svc.stateStream,
      invite: aliceHarness.svc.invite,
      accept: aliceHarness.svc.accept,
      reject: aliceHarness.svc.reject,
      hangup: () => aliceHarness.svc.hangup(),
      repo: aliceRepo,
      navigator: _NoopNav(),
      peerInfoLookup: (_) async => const MeshPeerInfo(name: 'Bob'),
      selfDevicePk: _peer(1),
      transportLabelForPeer: (_) => 'Bonjour',
    );
    final bobCoord = MeshVoiceUiCoordinator(
      stateStream: bobHarness.svc.stateStream,
      invite: bobHarness.svc.invite,
      accept: bobHarness.svc.accept,
      reject: bobHarness.svc.reject,
      hangup: () => bobHarness.svc.hangup(),
      repo: bobRepo,
      navigator: _NoopNav(),
      peerInfoLookup: (_) async => const MeshPeerInfo(name: 'Alice'),
      selfDevicePk: _peer(2),
      transportLabelForPeer: (_) => 'Bonjour',
    );
    aliceCoord.start();
    bobCoord.start();

    // Alice places a call to Bob.
    final callId = await aliceCoord.placeCall(_peer(2));
    expect(callId, isNotNull);

    // Wait for envelope delivery.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(bobHarness.svc.state, isA<IncomingState>());

    // Bob accepts.
    await bobHarness.svc.accept();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(aliceHarness.svc.state, isA<ActiveState>());
    expect(bobHarness.svc.state, isA<ActiveState>());

    // Alice hangs up.
    await aliceHarness.svc.hangup();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Both should have emitted history entries.
    // Alice's reason = userHangup (she initiated hangup).
    // Bob's reason = remoteHangup (he saw call_end from Alice).
    expect(aliceRepo.entries, hasLength(1));
    expect(aliceRepo.entries.single.endReason, 'userHangup');
    expect(bobRepo.entries, hasLength(1));
    expect(bobRepo.entries.single.endReason, 'remoteHangup');

    await aliceCoord.dispose();
    await bobCoord.dispose();
  });
}
