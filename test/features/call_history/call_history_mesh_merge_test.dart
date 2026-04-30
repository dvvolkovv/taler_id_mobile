import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_entry.dart';
import 'package:taler_id_mobile/features/call_history/presentation/screens/call_history_merge.dart';

MeshCallHistoryEntry _meshEntry({
  required int callId,
  required DateTime startedAt,
  String? peerName,
  String? peerUserId,
  bool isOutgoing = true,
  String endReason = 'userHangup',
  DateTime? activatedAt,
  int? durationSec,
  String? transport = 'bonjour',
}) =>
    MeshCallHistoryEntry(
      callId: callId,
      peerDevicePkBase64: 'AQIDBA==',
      peerUserId: peerUserId,
      peerName: peerName,
      isOutgoing: isOutgoing,
      startedAt: startedAt,
      activatedAt: activatedAt,
      endedAt: startedAt.add(const Duration(seconds: 30)),
      durationSec: durationSec,
      endReason: endReason,
      transport: transport,
    );

void main() {
  group('mergedHistoryEntries', () {
    test('mesh entries are converted to display rows with isMesh=true', () {
      final mesh = _meshEntry(
        callId: 0xCAFE,
        startedAt: DateTime.utc(2026, 4, 30, 10),
        peerName: 'Alice',
        peerUserId: 'u-1',
        durationSec: 30,
        activatedAt: DateTime.utc(2026, 4, 30, 10, 0, 1),
      );
      final result = mergedHistoryEntries(serverEntries: const [], meshEntries: [mesh]);
      expect(result, hasLength(1));
      expect(result.single.id, 'mesh-cafe');
      expect(result.single.isMesh, isTrue);
      expect(result.single.otherPartyName, 'Alice');
      expect(result.single.otherPartyId, 'u-1');
      expect(result.single.durationSec, 30);
      expect(result.single.isOutgoing, isTrue);
    });

    test('merged list is sorted by startedAt desc', () {
      final older = _meshEntry(callId: 1, startedAt: DateTime.utc(2026, 4, 30, 9));
      final newer = _meshEntry(callId: 2, startedAt: DateTime.utc(2026, 4, 30, 11));
      final server = HistoryDisplayRow(
        id: 'srv-1',
        otherPartyName: 'Server peer',
        otherPartyAvatar: null,
        otherPartyId: 'u-srv',
        startedAt: DateTime.utc(2026, 4, 30, 10),
        durationSec: 60,
        isOutgoing: false,
        isMissed: false,
        withAi: false,
        conversationId: null,
        isMesh: false,
        meshEndReason: null,
      );
      final result = mergedHistoryEntries(
        serverEntries: [server],
        meshEntries: [older, newer],
      );
      expect(result.map((r) => r.id), ['mesh-2', 'srv-1', 'mesh-1']);
    });

    test('mesh entry with peerName=null falls back to "Mesh-устройство <hex>"', () {
      final mesh = _meshEntry(
        callId: 1,
        startedAt: DateTime.utc(2026, 4, 30, 10),
        peerName: null,
      );
      final result = mergedHistoryEntries(serverEntries: const [], meshEntries: [mesh]);
      // base64 'AQIDBA==' → bytes [1, 2, 3, 4] → hex '01020304'
      expect(result.single.otherPartyName, 'Mesh-устройство 01020304');
    });

    test('isMissed true for never-activated invite-timeout', () {
      final mesh = _meshEntry(
        callId: 1,
        startedAt: DateTime.utc(2026),
        endReason: 'inviteTimeout',
        activatedAt: null,
      );
      final result = mergedHistoryEntries(serverEntries: const [], meshEntries: [mesh]);
      expect(result.single.isMissed, isTrue);
    });

    test('isMissed false for completed call (activatedAt non-null)', () {
      final mesh = _meshEntry(
        callId: 1,
        startedAt: DateTime.utc(2026),
        endReason: 'userHangup',
        activatedAt: DateTime.utc(2026),
      );
      final result = mergedHistoryEntries(serverEntries: const [], meshEntries: [mesh]);
      expect(result.single.isMissed, isFalse);
    });
  });
}
