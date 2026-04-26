import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/frame.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  group('Frame v2', () {
    final src = PeerId(Uint8List.fromList(List.generate(32, (i) => i)));
    final srcPk = PeerId.fromHex('a' * 64);

    test('encode/decode round-trip for HANDSHAKE', () {
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final frame = Frame(
        version: 2,
        type: FrameType.handshake,
        srcPk: src,
        payload: payload,
      );
      final bytes = frame.encode();
      expect(bytes.length, 1 + 1 + 2 + 32 + 5);
      final decoded = Frame.decode(bytes);
      expect(decoded.version, 2);
      expect(decoded.type, FrameType.handshake);
      expect(decoded.srcPk, equals(src));
      expect(decoded.payload, equals(payload));
    });

    test('encode correct layout', () {
      final payload = Uint8List.fromList([0xAA, 0xBB]);
      final frame = Frame(
        version: 2,
        type: FrameType.data,
        srcPk: src,
        payload: payload,
      );
      final bytes = frame.encode();
      expect(bytes[0], 2); // version
      expect(bytes[1], FrameType.data.index); // type
      expect(bytes[2], 0); // length high byte
      expect(bytes[3], 2); // length low byte
      expect(bytes.sublist(4, 36), equals(src.bytes));
      expect(bytes.sublist(36), equals(payload));
    });

    test('decode rejects a v1 frame (legacy mesh peer)', () {
      // Build a v1 data frame manually (bypassing Frame.encode which now writes v2).
      final payload = Uint8List.fromList([1, 2, 3]);
      final bytes = Uint8List(Frame.headerSize + payload.length);
      bytes[0] = 1; // legacy v1
      bytes[1] = FrameType.data.index;
      bytes[2] = 0;
      bytes[3] = payload.length;
      bytes.setRange(4, 36, srcPk.bytes);
      bytes.setRange(36, bytes.length, payload);

      expect(() => Frame.decode(bytes), throwsFormatException);
    });

    test('encode writes version byte = 2', () {
      final frame = Frame(
        version: 2,
        type: FrameType.data,
        srcPk: srcPk,
        payload: Uint8List(0),
      );
      final encoded = frame.encode();
      expect(encoded[0], 2);
    });

    test('decode rejects short buffer', () {
      expect(() => Frame.decode(Uint8List(10)), throwsA(isA<FormatException>()));
    });

    test('max payload 65535 bytes', () {
      final big = Uint8List(65535);
      final frame = Frame(
        version: 2,
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
          version: 2,
          type: FrameType.data,
          srcPk: src,
          payload: huge,
        ).encode(),
        throwsArgumentError,
      );
    });

    test('round-trips a v2 data frame with empty payload', () {
      final frame = Frame(
        version: 2,
        type: FrameType.data,
        srcPk: srcPk,
        payload: Uint8List(0),
      );
      final encoded = frame.encode();
      final decoded = Frame.decode(encoded);
      expect(decoded.version, 2);
      expect(decoded.type, FrameType.data);
      expect(decoded.srcPk, srcPk);
      expect(decoded.payload, Uint8List(0));
    });

    test('round-trips a v2 frame with binary payload', () {
      final payload = Uint8List.fromList(List.generate(100, (i) => i & 0xFF));
      final frame = Frame(
        version: 2,
        type: FrameType.handshake,
        srcPk: srcPk,
        payload: payload,
      );
      final decoded = Frame.decode(frame.encode());
      expect(decoded.payload, payload);
    });
  });
}
