import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/presentation/screens/chat_room_auto_pick.dart';

void main() {
  group('chatRoomAutoPickDecision', () {
    test('returns conflict when isInCall && !canAddLine', () {
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: 'u1',
          isInCall: true,
          canAddLine: false,
          isUserOnline: true,
          recentLkCallMs: null,
          nowMs: 1000,
        ),
        AutoPickDecision.conflict,
      );
    });

    test('returns lk for non-DIRECT conv (group)', () {
      expect(
        chatRoomAutoPickDecision(
          convType: 'GROUP',
          otherUserId: null,
          isInCall: false,
          canAddLine: true,
          isUserOnline: true,
          recentLkCallMs: null,
          nowMs: 1000,
        ),
        AutoPickDecision.lk,
      );
    });

    test('returns lk for DIRECT with null otherUserId', () {
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: null,
          isInCall: false,
          canAddLine: true,
          isUserOnline: true,
          recentLkCallMs: null,
          nowMs: 1000,
        ),
        AutoPickDecision.lk,
      );
    });

    test('returns lk when recent LK call < 30 min ago', () {
      const tenMin = 10 * 60 * 1000;
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: 'u1',
          isInCall: false,
          canAddLine: true,
          isUserOnline: true,
          recentLkCallMs: 1000,
          nowMs: 1000 + tenMin,
        ),
        AutoPickDecision.lk,
      );
    });

    test('returns mesh when recent LK call > 30 min ago', () {
      const fortyMin = 40 * 60 * 1000;
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: 'u1',
          isInCall: false,
          canAddLine: true,
          isUserOnline: true,
          recentLkCallMs: 1000,
          nowMs: 1000 + fortyMin,
        ),
        AutoPickDecision.mesh,
      );
    });

    test('returns lk when peer is not online via mesh', () {
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: 'u1',
          isInCall: false,
          canAddLine: true,
          isUserOnline: false,
          recentLkCallMs: null,
          nowMs: 1000,
        ),
        AutoPickDecision.lk,
      );
    });

    test('returns mesh when DIRECT + online + no recent LK', () {
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: 'u1',
          isInCall: false,
          canAddLine: true,
          isUserOnline: true,
          recentLkCallMs: null,
          nowMs: 1000,
        ),
        AutoPickDecision.mesh,
      );
    });
  });
}
