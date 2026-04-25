import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/noise/noise_symmetric.dart';

void main() {
  group('NoiseSymmetricState', () {
    const protocolName = 'Noise_IK_25519_ChaChaPoly_SHA256';

    test('initializeSymmetric sets ck = h = protocolName bytes padded if <= 32 bytes', () {
      final ss = NoiseSymmetricState.initializeSymmetric(protocolName);
      // "Noise_IK_25519_ChaChaPoly_SHA256" is exactly 32 bytes.
      expect(ss.handshakeHash.length, 32);
      expect(ss.chainingKey.length, 32);
      expect(ss.handshakeHash, equals(ss.chainingKey));
    });

    test('mixHash updates h deterministically', () {
      final a = NoiseSymmetricState.initializeSymmetric(protocolName);
      final b = NoiseSymmetricState.initializeSymmetric(protocolName);
      a.mixHash(Uint8List.fromList([1, 2, 3]));
      b.mixHash(Uint8List.fromList([1, 2, 3]));
      expect(a.handshakeHash, equals(b.handshakeHash));

      final c = NoiseSymmetricState.initializeSymmetric(protocolName);
      c.mixHash(Uint8List.fromList([4, 5, 6]));
      expect(a.handshakeHash, isNot(equals(c.handshakeHash)));
    });

    test('encryptAndHash without key returns plaintext', () async {
      final ss = NoiseSymmetricState.initializeSymmetric(protocolName);
      final pt = utf8.encode('hello');
      final ct = await ss.encryptAndHash(Uint8List.fromList(pt));
      expect(ct, equals(pt));
    });

    test('roundtrip: encrypt then decrypt with mirrored states', () async {
      final a = NoiseSymmetricState.initializeSymmetric(protocolName);
      final b = NoiseSymmetricState.initializeSymmetric(protocolName);

      final sharedKey = Uint8List.fromList(List.filled(32, 0x42));
      a.mixKey(sharedKey);
      b.mixKey(sharedKey);

      final pt = Uint8List.fromList(utf8.encode('secret message'));
      final ct = await a.encryptAndHash(pt);
      expect(ct.length, pt.length + 16); // ChaCha20-Poly1305 adds 16-byte tag

      final dec = await b.decryptAndHash(ct);
      expect(dec, equals(pt));
    });

    test('split returns two 32-byte transport keys', () {
      final ss = NoiseSymmetricState.initializeSymmetric(protocolName);
      final (k1, k2) = ss.split();
      expect(k1.length, 32);
      expect(k2.length, 32);
      expect(k1, isNot(equals(k2)));
    });
  });
}
