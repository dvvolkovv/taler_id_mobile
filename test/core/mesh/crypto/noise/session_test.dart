import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/noise/session.dart';

void main() {
  group('NoiseSession', () {
    late Uint8List keyAtoB;
    late Uint8List keyBtoA;

    setUp(() {
      keyAtoB = Uint8List.fromList(List.filled(32, 1));
      keyBtoA = Uint8List.fromList(List.filled(32, 2));
    });

    test('encrypt then decrypt round-trip', () async {
      final alice = NoiseSession(sendKey: keyAtoB, recvKey: keyBtoA);
      final bob = NoiseSession(sendKey: keyBtoA, recvKey: keyAtoB);
      final msg = Uint8List.fromList(utf8.encode('hello bob'));
      final ct = await alice.encrypt(msg);
      expect(ct.length, msg.length + 16);
      final dec = await bob.decrypt(ct);
      expect(dec, equals(msg));
    });

    test('counters increment per message', () async {
      final alice = NoiseSession(sendKey: keyAtoB, recvKey: keyBtoA);
      final bob = NoiseSession(sendKey: keyBtoA, recvKey: keyAtoB);
      final m1 = await alice.encrypt(Uint8List.fromList([1]));
      final m2 = await alice.encrypt(Uint8List.fromList([2]));
      expect(await bob.decrypt(m1), equals([1]));
      expect(await bob.decrypt(m2), equals([2]));
    });

    test('rejects tampered ciphertext', () async {
      final alice = NoiseSession(sendKey: keyAtoB, recvKey: keyBtoA);
      final bob = NoiseSession(sendKey: keyBtoA, recvKey: keyAtoB);
      final ct = await alice.encrypt(Uint8List.fromList([1, 2, 3]));
      ct[0] ^= 0xFF;
      await expectLater(bob.decrypt(ct), throwsA(isA<Exception>()));
    });

    test('replay detected via sliding window', () async {
      final alice = NoiseSession(sendKey: keyAtoB, recvKey: keyBtoA);
      final bob = NoiseSession(sendKey: keyBtoA, recvKey: keyAtoB);
      final ct = await alice.encrypt(Uint8List.fromList([1, 2, 3]));
      await bob.decrypt(ct);
      // Bob's counter advanced; re-submitting same ciphertext fails on nonce mismatch.
      await expectLater(bob.decrypt(ct), throwsA(isA<Exception>()));
    });
  });
}
