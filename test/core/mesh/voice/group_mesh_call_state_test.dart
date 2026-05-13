import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';

void main() {
  group('GroupMeshCallState equality', () {
    test('Idle equality', () {
      expect(const GMCIdle(), const GMCIdle());
    });

    test('Lobby with same roster is equal', () {
      final a = GMCLobby(
        roomId: 'r1',
        hostDevicePk: 'h',
        roster: const [
          GMCParticipant(devicePk: 'p1', userId: 'u1', status: GMCStatus.calling),
        ],
      );
      final b = GMCLobby(
        roomId: 'r1',
        hostDevicePk: 'h',
        roster: const [
          GMCParticipant(devicePk: 'p1', userId: 'u1', status: GMCStatus.calling),
        ],
      );
      expect(a, b);
    });

    test('Active with different durationSec is NOT equal', () {
      final a = GMCActive(roomId: 'r', roster: const [], durationSec: 10);
      final b = GMCActive(roomId: 'r', roster: const [], durationSec: 20);
      expect(a == b, isFalse);
    });

    test('Ended carries reason', () {
      const e = GMCEnded(reason: GMCEndReason.userHangup);
      expect(e.reason, GMCEndReason.userHangup);
    });
  });

  group('GMCParticipant', () {
    test('copyWith updates status only', () {
      const p = GMCParticipant(devicePk: 'a', userId: 'u', status: GMCStatus.calling);
      final p2 = p.copyWith(status: GMCStatus.joined);
      expect(p2.devicePk, 'a');
      expect(p2.userId, 'u');
      expect(p2.status, GMCStatus.joined);
    });

    test('participants with same fields are equal', () {
      const a = GMCParticipant(devicePk: 'a', userId: 'u', status: GMCStatus.calling);
      const b = GMCParticipant(devicePk: 'a', userId: 'u', status: GMCStatus.calling);
      expect(a, b);
    });

    test('isSelf flag preserved through copyWith', () {
      const p = GMCParticipant(devicePk: 'a', userId: 'u', status: GMCStatus.calling, isSelf: true);
      final p2 = p.copyWith(status: GMCStatus.joined);
      expect(p2.isSelf, isTrue);
    });
  });
}
