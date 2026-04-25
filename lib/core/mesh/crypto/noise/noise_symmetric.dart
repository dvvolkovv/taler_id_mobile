import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'noise_hkdf.dart';

/// Noise SymmetricState per Noise spec § 5.2.
///
/// Maintains the three mutable fields described in the spec:
///   - `ck`  (chainingKey)        — 32-byte HKDF chaining key
///   - `h`   (handshakeHash)      — 32-byte running handshake transcript hash
///   - `k`   (cipher key)         — optional 32-byte AEAD key (null = no key)
///   - `n`   (_nonce)             — 64-bit counter for ChaCha20-Poly1305
///
/// Configured for Noise_IK_25519_ChaChaPoly_SHA256.
class NoiseSymmetricState {
  static final _aead = Chacha20.poly1305Aead();

  Uint8List chainingKey;
  Uint8List handshakeHash;
  Uint8List? _key; // null = cipher not yet initialized
  int _nonce = 0;

  NoiseSymmetricState._({
    required this.chainingKey,
    required this.handshakeHash,
  });

  /// Spec § 5.2 — InitializeSymmetric(protocol_name):
  ///   if len(protocol_name) <= HASHLEN: h = protocol_name || zeroes
  ///   else: h = HASH(protocol_name)
  ///   ck = h
  factory NoiseSymmetricState.initializeSymmetric(String protocolName) {
    final nameBytes = Uint8List.fromList(utf8.encode(protocolName));
    final Uint8List h;
    if (nameBytes.length <= 32) {
      h = Uint8List(32);
      h.setRange(0, nameBytes.length, nameBytes);
    } else {
      h = Uint8List.fromList(crypto.sha256.convert(nameBytes).bytes);
    }
    return NoiseSymmetricState._(
      chainingKey: Uint8List.fromList(h),
      handshakeHash: h,
    );
  }

  /// Spec § 5.2 — MixHash(data): h = HASH(h || data)
  void mixHash(Uint8List data) {
    final combined = Uint8List(handshakeHash.length + data.length)
      ..setRange(0, handshakeHash.length, handshakeHash)
      ..setRange(handshakeHash.length, handshakeHash.length + data.length, data);
    handshakeHash = Uint8List.fromList(crypto.sha256.convert(combined).bytes);
  }

  /// Spec § 5.2 — MixKey(input_key_material):
  ///   ck, temp_k = HKDF(ck, input_key_material, 2)
  ///   k = temp_k; n = 0
  void mixKey(Uint8List dhOutput) {
    final outputs = NoiseHkdf.hkdf2(chainingKey, dhOutput);
    chainingKey = outputs[0];
    _key = outputs[1];
    _nonce = 0;
  }

  bool get hasKey => _key != null;

  /// Spec § 5.2 — EncryptAndHash(plaintext):
  ///   if k is empty: mixHash(plaintext); return plaintext
  ///   else: ct = ENCRYPT(k, n++, h, plaintext); mixHash(ct); return ct
  Future<Uint8List> encryptAndHash(Uint8List plaintext) async {
    if (!hasKey) {
      mixHash(plaintext);
      return plaintext;
    }
    final aad = Uint8List.fromList(handshakeHash); // snapshot before mixHash
    final nonceBytes = _noise12ByteNonce(_nonce);
    final secretBox = await _aead.encrypt(
      plaintext,
      secretKey: SecretKey(_key!),
      nonce: nonceBytes,
      aad: aad,
    );
    _nonce++;
    // Concatenate ciphertext || tag (16 bytes)
    final ct = Uint8List(secretBox.cipherText.length + secretBox.mac.bytes.length)
      ..setRange(0, secretBox.cipherText.length, secretBox.cipherText)
      ..setRange(
        secretBox.cipherText.length,
        secretBox.cipherText.length + secretBox.mac.bytes.length,
        secretBox.mac.bytes,
      );
    mixHash(ct);
    return ct;
  }

  /// Spec § 5.2 — DecryptAndHash(ciphertext):
  ///   if k is empty: mixHash(ciphertext); return ciphertext
  ///   else: pt = DECRYPT(k, n++, h, ciphertext); mixHash(ciphertext); return pt
  Future<Uint8List> decryptAndHash(Uint8List ciphertext) async {
    if (!hasKey) {
      mixHash(ciphertext);
      return ciphertext;
    }
    if (ciphertext.length < 16) {
      throw const FormatException('ciphertext too short for Poly1305 tag');
    }
    final aad = Uint8List.fromList(handshakeHash); // snapshot before mixHash
    final ct = ciphertext.sublist(0, ciphertext.length - 16);
    final macBytes = ciphertext.sublist(ciphertext.length - 16);
    final nonceBytes = _noise12ByteNonce(_nonce);
    final secretBox = SecretBox(ct, nonce: nonceBytes, mac: Mac(macBytes));
    final pt = await _aead.decrypt(
      secretBox,
      secretKey: SecretKey(_key!),
      aad: aad,
    );
    _nonce++;
    mixHash(ciphertext); // hash the ciphertext, NOT the plaintext
    return Uint8List.fromList(pt);
  }

  /// Spec § 5.2 — Split():
  ///   temp_k1, temp_k2 = HKDF(ck, empty, 2)
  ///   return (temp_k1, temp_k2)
  (Uint8List, Uint8List) split() {
    final outputs = NoiseHkdf.hkdf2(chainingKey, Uint8List(0));
    return (outputs[0], outputs[1]);
  }

  /// Noise spec uses 96-bit (12-byte) nonce: 4 zero bytes || 8-byte LE counter.
  List<int> _noise12ByteNonce(int counter) {
    final n = Uint8List(12);
    for (var i = 0; i < 8; i++) {
      n[4 + i] = (counter >> (8 * i)) & 0xFF;
    }
    return n;
  }
}
