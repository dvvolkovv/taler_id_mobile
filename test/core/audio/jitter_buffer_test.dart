import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/audio/jitter_buffer.dart';

void main() {
  group('JitterBuffer', () {
    test('returns frames in seq order when pushed in order', () {
      final jb = JitterBuffer(targetDepthFrames: 3);
      jb.push(seq: 1, payload: Uint8List.fromList([1]));
      jb.push(seq: 2, payload: Uint8List.fromList([2]));
      jb.push(seq: 3, payload: Uint8List.fromList([3]));

      final out1 = jb.pull();
      expect(out1?.payload, Uint8List.fromList([1]));
      expect(out1?.kind, JitterFrameKind.payload);
      final out2 = jb.pull();
      expect(out2?.payload, Uint8List.fromList([2]));
    });

    test('returns frames in seq order when pushed reordered', () {
      final jb = JitterBuffer(targetDepthFrames: 3);
      jb.push(seq: 2, payload: Uint8List.fromList([2]));
      jb.push(seq: 1, payload: Uint8List.fromList([1]));
      jb.push(seq: 3, payload: Uint8List.fromList([3]));

      final out1 = jb.pull();
      final out2 = jb.pull();
      final out3 = jb.pull();
      expect(out1?.payload, Uint8List.fromList([1]));
      expect(out2?.payload, Uint8List.fromList([2]));
      expect(out3?.payload, Uint8List.fromList([3]));
    });

    test('emits PLC frame when there is a gap of 1', () {
      final jb = JitterBuffer(targetDepthFrames: 2);
      jb.push(seq: 1, payload: Uint8List.fromList([1]));
      jb.push(seq: 3, payload: Uint8List.fromList([3]));

      expect(jb.pull()?.payload, Uint8List.fromList([1]));
      expect(jb.pull()?.kind, JitterFrameKind.plc);
      expect(jb.pull()?.payload, Uint8List.fromList([3]));
    });

    test('drops late frames whose seq is below current playout', () {
      final jb = JitterBuffer(targetDepthFrames: 2);
      jb.push(seq: 1, payload: Uint8List.fromList([1]));
      jb.push(seq: 2, payload: Uint8List.fromList([2]));
      jb.pull(); // playout advances past seq 1
      jb.pull(); // playout advances past seq 2
      jb.push(seq: 1, payload: Uint8List.fromList([99])); // late, must be dropped

      final next = jb.pull();
      // No payload available — gap → PLC or null when buffer empty
      expect(next?.kind, isNot(JitterFrameKind.payload));
    });

    test('returns null when buffer is empty', () {
      final jb = JitterBuffer(targetDepthFrames: 3);
      expect(jb.pull(), isNull);
    });
  });
}
