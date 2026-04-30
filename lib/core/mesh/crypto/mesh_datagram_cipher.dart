import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Direction tag for sub-key derivation. Each peer pair has two derived
/// keys: one for caller→callee traffic and one for callee→caller. This
/// prevents nonce reuse across the two directions over a shared transport
/// key (mandatory for AEAD security).
enum CipherDirection {
  aToB,
  bToA,
}

/// AEAD cipher for mesh-voice datagram payloads. Reuses the 32-byte
/// Noise IK transport secret (from the handshake's `split()`) to derive
/// a per-direction ChaCha20-Poly1305 key via HKDF. Each frame uses a
/// 12-byte nonce constructed as `direction (1) || zero (3) || seq (8 BE)`.
///
/// Replay protection: receivers track the maximum seq seen and drop any
/// frame whose seq is below `max_seen − 64`. Within the window, the same
/// seq cannot be accepted twice.
///
/// See `docs/superpowers/specs/2026-04-29-mesh-voice-call-phase3-design.md`
/// section "Encryption (MeshDatagramCipher)".
class MeshDatagramCipher {
  static const int _replayWindowSize = 64;

  final SecretKey _key;
  final CipherDirection _direction;

  // Replay-window state — only meaningful when this cipher is used to
  // decrypt inbound frames. Outbound encryption ignores it.
  int _maxSeqSeen = -1;
  final Set<int> _seenInWindow = <int>{};

  MeshDatagramCipher._(this._key, this._direction);

  /// Derive a cipher for [direction] from a 32-byte Noise transport secret.
  static Future<MeshDatagramCipher> derive({
    required Uint8List transportSecret,
    required CipherDirection direction,
  }) async {
    if (transportSecret.length != 32) {
      throw ArgumentError(
          'transportSecret must be 32 bytes, got ${transportSecret.length}');
    }
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final info = direction == CipherDirection.aToB
        ? const [
            0x6d, 0x65, 0x73, 0x68, 0x44, 0x47, 0x2d, 0x61, 0x32, 0x62
          ] // 'meshDG-a2b'
        : const [
            0x6d, 0x65, 0x73, 0x68, 0x44, 0x47, 0x2d, 0x62, 0x32, 0x61
          ]; // 'meshDG-b2a'
    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(transportSecret),
      info: info,
    );
    return MeshDatagramCipher._(derivedKey, direction);
  }

  /// Encrypt [plaintext] with the given sequence number. Returns ciphertext+tag.
  Future<Uint8List> encrypt(
      {required int seq, required Uint8List plaintext}) async {
    final algorithm = Chacha20.poly1305Aead();
    final nonce = _buildNonce(seq);
    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: _key,
      nonce: nonce,
    );
    final out = Uint8List(
        secretBox.cipherText.length + secretBox.mac.bytes.length);
    out.setAll(0, secretBox.cipherText);
    out.setAll(secretBox.cipherText.length, secretBox.mac.bytes);
    return out;
  }

  /// Decrypt [ciphertext] (ciphertext+tag concatenated). Throws if AEAD
  /// authentication fails OR if [seq] is outside the replay window.
  Future<Uint8List> decrypt(
      {required int seq, required Uint8List ciphertext}) async {
    if (ciphertext.length < 16) {
      throw FormatException(
          'ciphertext too short (need at least 16 bytes for tag)');
    }
    if (!_replayCheck(seq)) {
      throw Exception('replay-window violation: seq=$seq max=$_maxSeqSeen');
    }
    final algorithm = Chacha20.poly1305Aead();
    final ctOnly = ciphertext.sublist(0, ciphertext.length - 16);
    final mac = Mac(ciphertext.sublist(ciphertext.length - 16));
    final nonce = _buildNonce(seq);
    final secretBox = SecretBox(ctOnly, nonce: nonce, mac: mac);
    final pt = await algorithm.decrypt(secretBox, secretKey: _key);
    _replayAccept(seq);
    return Uint8List.fromList(pt);
  }

  List<int> _buildNonce(int seq) {
    final n = Uint8List(12);
    n[0] = _direction == CipherDirection.aToB ? 0x00 : 0x01;
    // bytes 1..3 = zero (already zero-initialised)
    // bytes 4..11 = seq big-endian
    final view = ByteData.view(n.buffer);
    view.setUint64(4, seq, Endian.big);
    return n;
  }

  bool _replayCheck(int seq) {
    if (_maxSeqSeen < 0) return true; // first frame ever
    if (seq <= _maxSeqSeen - _replayWindowSize) return false; // outside window
    if (_seenInWindow.contains(seq)) return false; // already accepted
    return true;
  }

  void _replayAccept(int seq) {
    if (seq > _maxSeqSeen) {
      _maxSeqSeen = seq;
      // Prune entries that have fallen out of the new window.
      _seenInWindow
          .removeWhere((s) => s <= _maxSeqSeen - _replayWindowSize);
    }
    _seenInWindow.add(seq);
  }
}
