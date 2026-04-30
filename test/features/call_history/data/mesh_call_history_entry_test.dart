import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_entry.dart';

void main() {
  group('MeshCallHistoryEntry', () {
    test('round-trips through toJson/fromJson with all fields populated', () {
      final entry = MeshCallHistoryEntry(
        callId: 0xCAFEBABE,
        peerDevicePkBase64: 'AQIDBA==',
        peerUserId: 'user-123',
        peerName: 'Alice',
        isOutgoing: true,
        startedAt: DateTime.utc(2026, 4, 29, 10, 15, 30),
        activatedAt: DateTime.utc(2026, 4, 29, 10, 15, 32),
        endedAt: DateTime.utc(2026, 4, 29, 10, 16, 5),
        durationSec: 33,
        endReason: 'userHangup',
        transport: 'bonjour',
      );
      final round = MeshCallHistoryEntry.fromJson(entry.toJson());
      expect(round, entry);
    });

    test('round-trips with nullable fields null', () {
      final entry = MeshCallHistoryEntry(
        callId: 1,
        peerDevicePkBase64: 'AA==',
        peerUserId: null,
        peerName: null,
        isOutgoing: false,
        startedAt: DateTime.utc(2026, 4, 29, 10, 15, 30),
        activatedAt: null,
        endedAt: DateTime.utc(2026, 4, 29, 10, 15, 35),
        durationSec: null,
        endReason: 'rejectedByCallee',
        transport: null,
      );
      final round = MeshCallHistoryEntry.fromJson(entry.toJson());
      expect(round, entry);
    });

    test('equality and hashCode work field-by-field', () {
      final a = MeshCallHistoryEntry(
        callId: 1,
        peerDevicePkBase64: 'X',
        peerUserId: null,
        peerName: null,
        isOutgoing: true,
        startedAt: DateTime.utc(2026),
        activatedAt: null,
        endedAt: DateTime.utc(2026),
        durationSec: null,
        endReason: 'userHangup',
        transport: null,
      );
      final b = MeshCallHistoryEntry(
        callId: 1,
        peerDevicePkBase64: 'X',
        peerUserId: null,
        peerName: null,
        isOutgoing: true,
        startedAt: DateTime.utc(2026),
        activatedAt: null,
        endedAt: DateTime.utc(2026),
        durationSec: null,
        endReason: 'userHangup',
        transport: null,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
