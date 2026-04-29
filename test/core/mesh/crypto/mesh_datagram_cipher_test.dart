import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/mesh_datagram_cipher.dart';

void main() {
  group('MeshDatagramCipher', () {
    // 32-byte transport secret (in production this comes from the Noise IK
    // handshake's split() output).
    final transportSecret =
        Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    test('encrypt → decrypt round-trip recovers plaintext', () async {
      final outboundCipher = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.aToB,
      );
      final inboundCipher = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.aToB,
      );

      final pt = Uint8List.fromList(List<int>.generate(80, (i) => i));
      final ct = await outboundCipher.encrypt(seq: 1, plaintext: pt);
      expect(ct.length, greaterThan(pt.length),
          reason: 'ciphertext must include 16-byte auth tag');

      final dec = await inboundCipher.decrypt(seq: 1, ciphertext: ct);
      expect(dec, pt);
    });

    test('decryption with wrong direction fails', () async {
      final aOut = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.aToB,
      );
      final bOut = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.bToA,
      );

      final pt = Uint8List.fromList([1, 2, 3, 4]);
      final ct = await aOut.encrypt(seq: 1, plaintext: pt);

      await expectLater(
        bOut.decrypt(seq: 1, ciphertext: ct),
        throwsA(isA<Exception>()),
      );
    });

    test('replay window drops out-of-window seq', () async {
      final inbound = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.aToB,
      );
      final outbound = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.aToB,
      );

      final pt = Uint8List.fromList([42]);
      // Receive seq 100 first.
      final ct100 = await outbound.encrypt(seq: 100, plaintext: pt);
      await inbound.decrypt(seq: 100, ciphertext: ct100);

      // Then a frame with seq 30 — older than (max_seen − 64) = 36, must drop.
      final ct30 = await outbound.encrypt(seq: 30, plaintext: pt);
      await expectLater(
        inbound.decrypt(seq: 30, ciphertext: ct30),
        throwsA(isA<Exception>()),
      );

      // Frame with seq 99 (within window: 100 - 64 = 36 ≤ 99 ≤ 100) — accept.
      final ct99 = await outbound.encrypt(seq: 99, plaintext: pt);
      final out = await inbound.decrypt(seq: 99, ciphertext: ct99);
      expect(out, pt);

      // Re-decrypting the same seq 99 — must drop (replay).
      await expectLater(
        inbound.decrypt(seq: 99, ciphertext: ct99),
        throwsA(isA<Exception>()),
      );
    });
  });
}
