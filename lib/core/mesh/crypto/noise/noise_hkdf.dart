import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// Noise-style HKDF using HMAC-SHA256 (synchronous via package:crypto).
///
/// Semantics from Noise spec section 4.3:
///   HKDF(chainingKey, inputKeyMaterial, n) → list of n 32-byte outputs.
///
/// Per spec:
///   TempKey   = HMAC(chainingKey, inputKeyMaterial)
///   Output[1] = HMAC(TempKey, byte(1))
///   Output[i] = HMAC(TempKey, Output[i-1] || byte(i))  for i > 1
class NoiseHkdf {
  static List<Uint8List> hkdf2(Uint8List ck, Uint8List ikm) =>
      _hkdfN(ck, ikm, 2);

  static List<Uint8List> hkdf3(Uint8List ck, Uint8List ikm) =>
      _hkdfN(ck, ikm, 3);

  static List<Uint8List> _hkdfN(Uint8List ck, Uint8List ikm, int n) {
    final tempKey = _hmac(ck, ikm);
    final outputs = <Uint8List>[];
    Uint8List prev = Uint8List(0);
    for (var i = 1; i <= n; i++) {
      final input = Uint8List(prev.length + 1)
        ..setRange(0, prev.length, prev)
        ..[prev.length] = i;
      final out = _hmac(tempKey, input);
      outputs.add(out);
      prev = out;
    }
    return outputs;
  }

  static Uint8List _hmac(Uint8List key, Uint8List data) {
    final mac = crypto.Hmac(crypto.sha256, key).convert(data);
    return Uint8List.fromList(mac.bytes);
  }
}
