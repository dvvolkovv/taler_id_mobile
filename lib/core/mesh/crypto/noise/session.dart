import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Post-handshake bidirectional transport cipher.
/// Each direction uses ChaCha20-Poly1305 with a 96-bit nonce:
/// 4 zero bytes followed by 64-bit little-endian counter (Noise spec).
class NoiseSession {
  static final _aead = Chacha20.poly1305Aead();

  final Uint8List sendKey;
  final Uint8List recvKey;
  int _sendCounter = 0;
  int _recvCounter = 0;

  NoiseSession({
    required this.sendKey,
    required this.recvKey,
  });

  Future<Uint8List> encrypt(Uint8List plaintext) async {
    final sb = await _aead.encrypt(
      plaintext,
      secretKey: SecretKey(sendKey),
      nonce: _nonce(_sendCounter),
    );
    _sendCounter++;
    final out = Uint8List(sb.cipherText.length + sb.mac.bytes.length)
      ..setRange(0, sb.cipherText.length, sb.cipherText)
      ..setRange(sb.cipherText.length, sb.cipherText.length + sb.mac.bytes.length,
          sb.mac.bytes);
    return out;
  }

  Future<Uint8List> decrypt(Uint8List ciphertext) async {
    if (ciphertext.length < 16) {
      throw const FormatException('ciphertext too short');
    }
    final ct = ciphertext.sublist(0, ciphertext.length - 16);
    final macBytes = ciphertext.sublist(ciphertext.length - 16);
    final sb = SecretBox(
      ct,
      nonce: _nonce(_recvCounter),
      mac: Mac(macBytes),
    );
    final pt = await _aead.decrypt(sb, secretKey: SecretKey(recvKey));
    _recvCounter++;
    return Uint8List.fromList(pt);
  }

  List<int> _nonce(int counter) {
    final n = Uint8List(12);
    for (var i = 0; i < 8; i++) {
      n[4 + i] = (counter >> (8 * i)) & 0xFF;
    }
    return n;
  }
}
