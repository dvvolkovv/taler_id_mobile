import 'dart:typed_data';

import 'peer_id.dart';

enum FrameType {
  handshake, // Noise IK msg1 or msg2
  data, // Session-encrypted payload
  keepalive,
  disconnect,
}

class Frame {
  static const int supportedVersion = 2;
  static const int headerSize = 1 + 1 + 2 + 32; // 36
  static const int maxPayload = 65535;

  final int version;
  final FrameType type;
  final PeerId srcPk;
  final Uint8List payload;

  Frame({
    required this.version,
    required this.type,
    required this.srcPk,
    required this.payload,
  });

  Uint8List encode() {
    if (payload.length > maxPayload) {
      throw ArgumentError('Frame payload over $maxPayload bytes');
    }
    final total = headerSize + payload.length;
    final bytes = Uint8List(total);
    bytes[0] = version;
    bytes[1] = type.index;
    bytes[2] = (payload.length >> 8) & 0xFF;
    bytes[3] = payload.length & 0xFF;
    bytes.setRange(4, 36, srcPk.bytes);
    bytes.setRange(36, total, payload);
    return bytes;
  }

  static Frame decode(Uint8List bytes) {
    if (bytes.length < headerSize) {
      throw const FormatException('Frame too short');
    }
    final version = bytes[0];
    if (version != supportedVersion) {
      throw FormatException('Unsupported frame version: $version');
    }
    final typeIdx = bytes[1];
    if (typeIdx < 0 || typeIdx >= FrameType.values.length) {
      throw FormatException('Unknown frame type: $typeIdx');
    }
    final length = (bytes[2] << 8) | bytes[3];
    if (bytes.length < headerSize + length) {
      throw const FormatException('Frame payload truncated');
    }
    return Frame(
      version: version,
      type: FrameType.values[typeIdx],
      srcPk: PeerId(Uint8List.fromList(bytes.sublist(4, 36))),
      payload: Uint8List.fromList(bytes.sublist(36, 36 + length)),
    );
  }
}
