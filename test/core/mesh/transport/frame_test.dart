import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/frame.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  group('Frame', () {
    final src = PeerId(Uint8List.fromList(List.generate(32, (i) => i)));

    test('encode/decode round-trip for HANDSHAKE', () {
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final frame = Frame(
        version: 1,
        type: FrameType.handshake,
        srcPk: src,
        payload: payload,
      );
      final bytes = frame.encode();
      expect(bytes.length, 1 + 1 + 2 + 32 + 5);
      final decoded = Frame.decode(bytes);
      expect(decoded.version, 1);
      expect(decoded.type, FrameType.handshake);
      expect(decoded.srcPk, equals(src));
      expect(decoded.payload, equals(payload));
    });

    test('encode correct layout', () {
      final payload = Uint8List.fromList([0xAA, 0xBB]);
      final frame = Frame(
        version: 1,
        type: FrameType.data,
        srcPk: src,
        payload: payload,
      );
      final bytes = frame.encode();
      expect(bytes[0], 1); // version
      expect(bytes[1], FrameType.data.index); // type
      expect(bytes[2], 0); // length high byte
      expect(bytes[3], 2); // length low byte
      expect(bytes.sublist(4, 36), equals(src.bytes));
      expect(bytes.sublist(36), equals(payload));
    });

    test('decode rejects wrong version', () {
      final payload = Uint8List(0);
      final frame = Frame(
        version: 2,
        type: FrameType.keepalive,
        srcPk: src,
        payload: payload,
      );
      expect(() => Frame.decode(frame.encode()), throwsA(isA<FormatException>()));
    });

    test('decode rejects short buffer', () {
      expect(() => Frame.decode(Uint8List(10)), throwsA(isA<FormatException>()));
    });

    test('max payload 65535 bytes', () {
      final big = Uint8List(65535);
      final frame = Frame(
        version: 1,
        type: FrameType.data,
        srcPk: src,
        payload: big,
      );
      final bytes = frame.encode();
      final decoded = Frame.decode(bytes);
      expect(decoded.payload.length, 65535);
    });

    test('rejects payload over 65535', () {
      final huge = Uint8List(65536);
      expect(
        () => Frame(
          version: 1,
          type: FrameType.data,
          srcPk: src,
          payload: huge,
        ).encode(),
        throwsArgumentError,
      );
    });
  });
}
