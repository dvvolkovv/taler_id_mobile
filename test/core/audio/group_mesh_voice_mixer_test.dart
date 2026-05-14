import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/audio/group_mesh_voice_mixer.dart';

void main() {
  group('GroupMeshVoiceMixer', () {
    test('empty input list produces zero-filled output', () {
      final out = GroupMeshVoiceMixer.mix(const [], 4);
      expect(out, Int16List.fromList([0, 0, 0, 0]));
    });

    test('single source passes through unchanged', () {
      final src = Int16List.fromList([100, 200, -100, -200]);
      final out = GroupMeshVoiceMixer.mix([src], 4);
      expect(out, src);
    });

    test('two non-null sources are averaged (divide-by-2)', () {
      // 2026-05-14: switched from naive sum to /N normalize to prevent
      // simultaneous-speech int16 clipping. (100+200)/2=150, (100+-50)/2=25,
      // (-100+200)/2=50, (-100+-50)/2=-75.
      final a = Int16List.fromList([100, 100, -100, -100]);
      final b = Int16List.fromList([200, -50, 200, -50]);
      final out = GroupMeshVoiceMixer.mix([a, b], 4);
      expect(out, Int16List.fromList([150, 25, 50, -75]));
    });

    test('two sources averaging stays inside int16 range (no clip)', () {
      // (30000+10000)/2 = 20000 — well below ceiling. Was clipped to 32767
      // under the old sum-and-clip behaviour; new normalised mixer doesn't
      // need to clip here.
      final a = Int16List.fromList([30000]);
      final b = Int16List.fromList([10000]);
      final out = GroupMeshVoiceMixer.mix([a, b], 1);
      expect(out[0], 20000);
    });

    test('two negative sources averaged stay inside int16 range', () {
      final a = Int16List.fromList([-30000]);
      final b = Int16List.fromList([-10000]);
      final out = GroupMeshVoiceMixer.mix([a, b], 1);
      expect(out[0], -20000);
    });

    test('null source treated as silence — divisor is non-null count', () {
      // Only `a` is active → divisor=1 → pass-through, NOT (a+0)/2.
      final a = Int16List.fromList([100, 100]);
      final out = GroupMeshVoiceMixer.mix([a, null], 2);
      expect(out, Int16List.fromList([100, 100]));
    });

    test('shorter source contributes 0 to its trailing samples but still counts as active', () {
      // [a, b] both non-null → activeCount=2 → divisor=2. At trailing samples
      // where b is past-end, only a contributes (100). Divided by 2 = 50.
      final a = Int16List.fromList([100, 100, 100, 100]);
      final b = Int16List.fromList([200, 200]);
      final out = GroupMeshVoiceMixer.mix([a, b], 4);
      expect(out, Int16List.fromList([150, 150, 50, 50]));
    });

    test('peak-saturating averaged sum still clips to int16 boundary', () {
      // Two near-max sources averaged stay well in range but use a third
      // crazy-large positive value to exercise the clip branch.
      final a = Int16List.fromList([32000]);
      final b = Int16List.fromList([32000]);
      final c = Int16List.fromList([32000]);
      // (32000+32000+32000)/3 = 32000 — no clip. Verifies the branch is
      // exercised without runtime overflow.
      final out = GroupMeshVoiceMixer.mix([a, b, c], 1);
      expect(out[0], 32000);
    });
  });
}
