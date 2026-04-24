import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/features/mesh/domain/entities/mesh_status.dart';

void main() {
  group('MeshStatus', () {
    test('initial has no peers and not running', () {
      const s = MeshStatus.initial();
      expect(s.running, isFalse);
      expect(s.peerCount, 0);
      expect(s.visibilityByContactUserId, isEmpty);
    });

    test('copyWith keeps unchanged fields', () {
      const a = MeshStatus.initial();
      final b = a.copyWith(running: true, peerCount: 3);
      expect(b.running, isTrue);
      expect(b.peerCount, 3);
      expect(b.visibilityByContactUserId, isEmpty);
    });

    test('equality by fields', () {
      expect(
        const MeshStatus(running: true, peerCount: 2, visibilityByContactUserId: {'a': true}),
        equals(const MeshStatus(running: true, peerCount: 2, visibilityByContactUserId: {'a': true})),
      );
    });
  });
}
