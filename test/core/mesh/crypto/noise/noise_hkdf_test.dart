import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/noise/noise_hkdf.dart';

Uint8List _hex(String s) {
  final n = s.length ~/ 2;
  final bytes = Uint8List(n);
  for (var i = 0; i < n; i++) {
    bytes[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

void main() {
  group('Noise HKDF', () {
    test('hkdf2 produces two 32-byte outputs', () {
      final ck = Uint8List.fromList(List.filled(32, 0));
      final ikm = Uint8List.fromList(List.filled(32, 1));
      final outputs = NoiseHkdf.hkdf2(ck, ikm);
      expect(outputs.length, 2);
      expect(outputs[0].length, 32);
      expect(outputs[1].length, 32);
    });

    test('hkdf3 produces three 32-byte outputs', () {
      final ck = Uint8List.fromList(List.filled(32, 0));
      final ikm = Uint8List.fromList(List.filled(32, 1));
      final outputs = NoiseHkdf.hkdf3(ck, ikm);
      expect(outputs.length, 3);
      for (final o in outputs) {
        expect(o.length, 32);
      }
    });

    test('deterministic for same inputs', () {
      final ck = _hex('00' * 32);
      final ikm = _hex('11' * 32);
      final a = NoiseHkdf.hkdf2(ck, ikm);
      final b = NoiseHkdf.hkdf2(ck, ikm);
      expect(a[0], equals(b[0]));
      expect(a[1], equals(b[1]));
    });

    test('different ikm produces different outputs', () {
      final ck = _hex('00' * 32);
      final a = NoiseHkdf.hkdf2(ck, _hex('11' * 32));
      final b = NoiseHkdf.hkdf2(ck, _hex('22' * 32));
      expect(a[0], isNot(equals(b[0])));
    });
  });
}
