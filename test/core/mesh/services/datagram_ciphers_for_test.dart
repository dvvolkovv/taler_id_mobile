import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/mesh_datagram_cipher.dart';

// This test validates the *direction-derivation* logic only, not the
// full MeshMessagingService wiring (covered by integration tests). We
// derive ciphers manually with known direction tags and verify that
// alice's outbound matches bob's inbound on a roundtrip.
void main() {
  test('alice.outbound + bob.inbound ciphers interoperate (aToB direction)', () async {
    final secret = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    // Alice has lower pk → she is "a". Outbound = aToB.
    final aliceOut = await MeshDatagramCipher.derive(
      transportSecret: secret,
      direction: CipherDirection.aToB,
    );
    // Bob is "b". Inbound = aToB (he reads alice's aToB stream).
    final bobIn = await MeshDatagramCipher.derive(
      transportSecret: secret,
      direction: CipherDirection.aToB,
    );

    final pt = Uint8List.fromList([1, 2, 3, 4, 5]);
    final ct = await aliceOut.encrypt(seq: 7, plaintext: pt);
    final dec = await bobIn.decrypt(seq: 7, ciphertext: ct);
    expect(dec, pt);
  });

  test('alice.inbound + bob.outbound ciphers interoperate (bToA direction)', () async {
    final secret = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    // Alice = "a". Inbound = bToA (she reads bob's bToA stream).
    final aliceIn = await MeshDatagramCipher.derive(
      transportSecret: secret,
      direction: CipherDirection.bToA,
    );
    // Bob = "b". Outbound = bToA.
    final bobOut = await MeshDatagramCipher.derive(
      transportSecret: secret,
      direction: CipherDirection.bToA,
    );

    final pt = Uint8List.fromList([99]);
    final ct = await bobOut.encrypt(seq: 1, plaintext: pt);
    final dec = await aliceIn.decrypt(seq: 1, ciphertext: ct);
    expect(dec, pt);
  });
}
