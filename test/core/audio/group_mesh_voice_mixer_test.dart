import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/audio/group_mesh_voice_mixer.dart';

void main() {
  group('GroupMeshVoiceMixer', () {
    test('empty input list produces zero-filled output', () {
      final out = GroupMeshVoiceMixer.mix(const [], 4);
      expect(out, Int16List.fromList([0, 0, 0, 0]));
    });

    test('single source passes through', () {
      final src = Int16List.fromList([100, 200, -100, -200]);
      final out = GroupMeshVoiceMixer.mix([src], 4);
      expect(out, src);
    });

    test('two sources are summed', () {
      final a = Int16List.fromList([100, 100, -100, -100]);
      final b = Int16List.fromList([200, -50, 200, -50]);
      final out = GroupMeshVoiceMixer.mix([a, b], 4);
      expect(out, Int16List.fromList([300, 50, 100, -150]));
    });

    test('sum overflowing int16 max clips to 32767', () {
      final a = Int16List.fromList([30000]);
      final b = Int16List.fromList([10000]);
      final out = GroupMeshVoiceMixer.mix([a, b], 1);
      expect(out[0], 32767);
    });

    test('sum below int16 min clips to -32768', () {
      final a = Int16List.fromList([-30000]);
      final b = Int16List.fromList([-10000]);
      final out = GroupMeshVoiceMixer.mix([a, b], 1);
      expect(out[0], -32768);
    });

    test('null source treated as silence', () {
      final a = Int16List.fromList([100, 100]);
      final out = GroupMeshVoiceMixer.mix([a, null], 2);
      expect(out, Int16List.fromList([100, 100]));
    });

    test('shorter source is zero-padded on the right', () {
      final a = Int16List.fromList([100, 100, 100, 100]);
      final b = Int16List.fromList([200, 200]);
      final out = GroupMeshVoiceMixer.mix([a, b], 4);
      expect(out, Int16List.fromList([300, 300, 100, 100]));
    });
  });
}
