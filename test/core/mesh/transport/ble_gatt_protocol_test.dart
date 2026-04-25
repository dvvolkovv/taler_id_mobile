import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/ble/ble_gatt_protocol.dart';

void main() {
  group('BleGattProtocol', () {
    test('service and characteristic UUIDs are stable', () {
      expect(BleGattProtocol.serviceUuid,
          equals('00005459-4c52-4944-4d45-534853470100'));
      expect(BleGattProtocol.characteristicUuid,
          equals('00005459-4c52-4944-4d45-534853470101'));
    });

    test('encodes frame with 2-byte big-endian length prefix', () {
      final payload = Uint8List.fromList([1, 2, 3, 4]);
      final encoded = BleGattProtocol.encodeFrame(payload);
      expect(encoded.length, equals(6));
      expect(encoded[0], equals(0));
      expect(encoded[1], equals(4));
      expect(encoded.sublist(2), equals(payload));
    });

    test('chunks output into MTU-sized writes', () {
      final payload = Uint8List(500);
      for (var i = 0; i < 500; i++) {
        payload[i] = i & 0xFF;
      }
      final chunks = BleGattProtocol.chunkForMtu(
        BleGattProtocol.encodeFrame(payload),
        mtu: 20,
      );
      expect(chunks.length, equals(26)); // ceil((500+2) / 20)
      expect(chunks.first.length, equals(20));
      // Last chunk may be shorter.
      expect(chunks.last.length, equals(2));
    });

    test('chunkForMtu throws on mtu < 1', () {
      expect(
        () => BleGattProtocol.chunkForMtu(Uint8List(10), mtu: 0),
        throwsArgumentError,
      );
    });

    test('FrameReassembler emits whole frame after split chunks arrive',
        () {
      final reassembler = FrameReassembler();
      final received = <Uint8List>[];
      reassembler.onFrame = (frame) => received.add(frame);

      final payload = Uint8List.fromList(List.generate(100, (i) => i & 0xFF));
      final encoded = BleGattProtocol.encodeFrame(payload);
      // Feed in 30-byte chunks.
      for (var i = 0; i < encoded.length; i += 30) {
        final end = (i + 30).clamp(0, encoded.length);
        reassembler.feed(Uint8List.sublistView(encoded, i, end));
      }

      expect(received, hasLength(1));
      expect(received.first, equals(payload));
    });

    test('FrameReassembler handles two frames in one chunk', () {
      final reassembler = FrameReassembler();
      final received = <Uint8List>[];
      reassembler.onFrame = (frame) => received.add(frame);

      final payloadA = Uint8List.fromList([1, 2, 3]);
      final payloadB = Uint8List.fromList([9, 8, 7, 6]);
      final combined = Uint8List.fromList([
        ...BleGattProtocol.encodeFrame(payloadA),
        ...BleGattProtocol.encodeFrame(payloadB),
      ]);
      reassembler.feed(combined);

      expect(received, hasLength(2));
      expect(received[0], equals(payloadA));
      expect(received[1], equals(payloadB));
    });

    test('FrameReassembler rejects zero-length frame', () {
      final reassembler = FrameReassembler();
      final received = <Uint8List>[];
      reassembler.onFrame = (frame) => received.add(frame);

      final bad = Uint8List.fromList([0, 0]); // length = 0
      reassembler.feed(bad);

      expect(received, isEmpty);
    });
  });
}
