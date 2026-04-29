import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_frame.dart';

void main() {
  group('MeshVoiceFrame', () {
    test('encode/decode round-trip preserves header + ciphertext', () {
      final ct = Uint8List.fromList(List<int>.generate(80, (i) => i + 1));
      final frame = MeshVoiceFrame(
        type: MeshVoiceFrameType.audio,
        callId: 0xAABBCCDD,
        seq: 42,
        ciphertext: ct,
      );
      final wire = frame.encode();
      expect(wire.length, 13 + 80, reason: 'header(13) + ciphertext(80)');
      expect(wire[0], 0x10, reason: 'audio type byte');

      final back = MeshVoiceFrame.decode(wire);
      expect(back.type, MeshVoiceFrameType.audio);
      expect(back.callId, 0xAABBCCDD);
      expect(back.seq, 42);
      expect(back.ciphertext, ct);
    });

    test('decode throws on truncated wire (less than header)', () {
      expect(
        () => MeshVoiceFrame.decode(Uint8List.fromList([0x10, 0, 0])),
        throwsA(isA<FormatException>()),
      );
    });

    test('decode throws on unknown type byte', () {
      // 13-byte header with type 0x99 (not audio/FEC/RTCP) + 1 byte payload.
      final bad = Uint8List(14)..[0] = 0x99;
      expect(
        () => MeshVoiceFrame.decode(bad),
        throwsA(isA<FormatException>()),
      );
    });

    test('big-endian seq + call_id encoded correctly', () {
      final frame = MeshVoiceFrame(
        type: MeshVoiceFrameType.audio,
        callId: 0x01020304,
        seq: 0x0807060504030201, // 64-bit pattern
        ciphertext: Uint8List.fromList([0xFF]),
      );
      final wire = frame.encode();
      // bytes 1..4 = call_id big-endian = 01 02 03 04
      expect(wire.sublist(1, 5), Uint8List.fromList([0x01, 0x02, 0x03, 0x04]));
      // bytes 5..12 = seq big-endian
      expect(wire.sublist(5, 13),
          Uint8List.fromList([0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01]));
    });
  });
}
