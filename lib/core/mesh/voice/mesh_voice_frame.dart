import 'dart:typed_data';

/// Frame-type byte enumeration. Only `audio` is emitted/parsed in Phase 3c;
/// the others are reserved for Phase 4+ (FEC, RTCP-lite).
enum MeshVoiceFrameType {
  audio(0x10),
  audioWithFec(0x11),
  rtcpLite(0x12);

  final int byte;
  const MeshVoiceFrameType(this.byte);

  static MeshVoiceFrameType fromByte(int b) {
    for (final t in MeshVoiceFrameType.values) {
      if (t.byte == b) return t;
    }
    throw FormatException(
        'MeshVoiceFrame: unknown type byte 0x${b.toRadixString(16).padLeft(2, '0')}');
  }
}

/// Wire-level frame for a single mesh-voice datagram.
///
/// Layout (big-endian):
///   byte 0:        type (one of [MeshVoiceFrameType])
///   bytes 1..4:    call_id (32-bit, identifies the call session)
///   bytes 5..12:   seq (64-bit, monotonically increasing per direction per call)
///   bytes 13..N:   ciphertext+tag (output of MeshDatagramCipher.encrypt)
///
/// Header is 13 bytes; total frame size is bounded by the underlying
/// transport's datagram MTU (1200 bytes for Bonjour UDP).
class MeshVoiceFrame {
  static const int headerLength = 13;

  final MeshVoiceFrameType type;
  final int callId;
  final int seq;
  final Uint8List ciphertext;

  MeshVoiceFrame({
    required this.type,
    required this.callId,
    required this.seq,
    required this.ciphertext,
  });

  Uint8List encode() {
    final out = Uint8List(headerLength + ciphertext.length);
    out[0] = type.byte;
    final view = ByteData.view(out.buffer);
    view.setUint32(1, callId, Endian.big);
    view.setUint64(5, seq, Endian.big);
    out.setAll(headerLength, ciphertext);
    return out;
  }

  static MeshVoiceFrame decode(Uint8List bytes) {
    if (bytes.length < headerLength) {
      throw FormatException(
          'MeshVoiceFrame: wire shorter than header (${bytes.length} < $headerLength)');
    }
    final type = MeshVoiceFrameType.fromByte(bytes[0]);
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    final callId = view.getUint32(1, Endian.big);
    final seq = view.getUint64(5, Endian.big);
    final ct = Uint8List.fromList(bytes.sublist(headerLength));
    return MeshVoiceFrame(type: type, callId: callId, seq: seq, ciphertext: ct);
  }
}
