import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  group('PeerId', () {
    test('constructs from 32-byte public key', () {
      final bytes = Uint8List.fromList(List.filled(32, 0x42));
      final peerId = PeerId(bytes);
      expect(peerId.bytes, bytes);
    });

    test('throws on invalid length', () {
      expect(() => PeerId(Uint8List(31)), throwsArgumentError);
      expect(() => PeerId(Uint8List(33)), throwsArgumentError);
    });

    test('equality by bytes', () {
      final a = PeerId(Uint8List.fromList(List.filled(32, 1)));
      final b = PeerId(Uint8List.fromList(List.filled(32, 1)));
      final c = PeerId(Uint8List.fromList(List.filled(32, 2)));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('hex encoding round-trip', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i));
      final peerId = PeerId(bytes);
      final hex = peerId.toHex();
      expect(hex.length, 64);
      expect(PeerId.fromHex(hex), equals(peerId));
    });

    test('short prefix (8 bytes hex) for BLE advertising', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i));
      expect(PeerId(bytes).shortPrefix(), '0001020304050607');
    });
  });
}
