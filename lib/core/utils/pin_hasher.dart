import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as legacy_crypto;
import 'package:cryptography/cryptography.dart';

/// Hashing for the app-unlock PIN.
///
/// The PIN used to be stored as a bare, unsalted SHA-256 of the four digits.
/// That is only 10 000 possible inputs, so anyone who reads the stored hash
/// recovers the PIN by hashing all of them — a rainbow table is not even
/// needed. The hash lives in the platform keystore, so reading it already
/// implies a compromised device, but the whole point of the PIN is to be the
/// barrier that still holds at that moment.
///
/// New hashes use PBKDF2-HMAC-SHA256 with a random per-PIN salt, stored as:
///
///   `pbkdf2$<iterations>$<base64 salt>$<base64 hash>`
///
/// [verify] still accepts the legacy 64-char hex form so existing installs keep
/// working; [needsRehash] tells the caller to upgrade the stored value once the
/// user has proved the PIN.
class PinHasher {
  static const _algorithmTag = 'pbkdf2';
  static const _iterations = 100000;
  static const _saltBytes = 16;
  static const _keyBits = 256;

  static final _random = Random.secure();

  /// Derives a storable hash for [pin], generating a fresh salt.
  static Future<String> hash(String pin) async {
    final salt = Uint8List.fromList(
      List<int>.generate(_saltBytes, (_) => _random.nextInt(256)),
    );
    final derived = await _derive(pin, salt);
    return '$_algorithmTag\$$_iterations\$${base64.encode(salt)}\$${base64.encode(derived)}';
  }

  /// True when [pin] matches [stored], in either the current or legacy format.
  static Future<bool> verify(String pin, String stored) async {
    if (stored.isEmpty) return false;

    if (!stored.startsWith('$_algorithmTag\$')) {
      // Legacy: unsalted SHA-256 hex.
      final legacy =
          legacy_crypto.sha256.convert(utf8.encode(pin)).toString();
      return _constantTimeEquals(legacy, stored);
    }

    final parts = stored.split('\$');
    if (parts.length != 4) return false;

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;

    final Uint8List salt;
    final String expected;
    try {
      salt = Uint8List.fromList(base64.decode(parts[2]));
      expected = parts[3];
    } catch (_) {
      return false;
    }

    final derived = await _derive(pin, salt, iterations: iterations);
    return _constantTimeEquals(base64.encode(derived), expected);
  }

  /// True when [stored] is in the legacy format and should be replaced after a
  /// successful unlock.
  static bool needsRehash(String stored) =>
      stored.isNotEmpty && !stored.startsWith('$_algorithmTag\$');

  static Future<List<int>> _derive(
    String pin,
    Uint8List salt, {
    int iterations = _iterations,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: _keyBits,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  /// Comparison that does not return early on the first differing character.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
