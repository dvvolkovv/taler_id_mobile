// Regression cover for the 2026-07-27 audit finding: the app PIN was stored as
// a bare unsalted SHA-256 of four digits, recoverable by hashing all 10 000
// possibilities.

import 'dart:convert';

import 'package:crypto/crypto.dart' as legacy_crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/utils/pin_hasher.dart';

void main() {
  test('accepts the PIN it hashed', () async {
    final stored = await PinHasher.hash('1234');
    expect(await PinHasher.verify('1234', stored), isTrue);
  });

  test('rejects a different PIN', () async {
    final stored = await PinHasher.hash('1234');
    expect(await PinHasher.verify('4321', stored), isFalse);
    expect(await PinHasher.verify('', stored), isFalse);
  });

  test('salts each hash, so the same PIN stores differently', () async {
    final a = await PinHasher.hash('1234');
    final b = await PinHasher.hash('1234');

    expect(a, isNot(equals(b)));
    // Both still verify — the salt travels with the hash.
    expect(await PinHasher.verify('1234', a), isTrue);
    expect(await PinHasher.verify('1234', b), isTrue);
  });

  test('never stores the plain SHA-256 of the PIN', () async {
    final stored = await PinHasher.hash('1234');
    final legacy = legacy_crypto.sha256.convert(utf8.encode('1234')).toString();

    expect(stored.contains(legacy), isFalse);
    expect(stored.startsWith('pbkdf2\$'), isTrue);
  });

  group('legacy hashes', () {
    final legacyStored =
        legacy_crypto.sha256.convert(utf8.encode('1234')).toString();

    test('still unlock, so existing installs keep working', () async {
      expect(await PinHasher.verify('1234', legacyStored), isTrue);
      expect(await PinHasher.verify('9999', legacyStored), isFalse);
    });

    test('are flagged for upgrade', () {
      expect(PinHasher.needsRehash(legacyStored), isTrue);
    });

    test('a current hash is not flagged', () async {
      expect(PinHasher.needsRehash(await PinHasher.hash('1234')), isFalse);
    });
  });

  group('malformed input', () {
    test('empty stored value never verifies', () async {
      expect(await PinHasher.verify('1234', ''), isFalse);
      expect(PinHasher.needsRehash(''), isFalse);
    });

    test('truncated or corrupt records are rejected, not thrown on', () async {
      expect(await PinHasher.verify('1234', 'pbkdf2\$100000'), isFalse);
      expect(
        await PinHasher.verify('1234', 'pbkdf2\$100000\$not-base64!\$x'),
        isFalse,
      );
      expect(
        await PinHasher.verify('1234', 'pbkdf2\$zero\$c2FsdA==\$aGFzaA=='),
        isFalse,
      );
    });
  });
}
