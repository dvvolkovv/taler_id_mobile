import 'dart:typed_data';

class PeerId {
  final Uint8List bytes;

  PeerId(Uint8List bytes)
      : bytes = Uint8List.fromList(bytes) {
    if (bytes.length != 32) {
      throw ArgumentError('PeerId requires 32 bytes, got ${bytes.length}');
    }
  }

  factory PeerId.fromHex(String hex) {
    if (hex.length != 64) {
      throw ArgumentError('PeerId hex must be 64 chars, got ${hex.length}');
    }
    final bytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return PeerId(bytes);
  }

  String toHex() {
    final buf = StringBuffer();
    for (final b in bytes) {
      buf.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  String shortPrefix() => toHex().substring(0, 16);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PeerId) return false;
    for (var i = 0; i < 32; i++) {
      if (bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var h = 0;
    for (final b in bytes) {
      h = (h * 31 + b) & 0x7FFFFFFF;
    }
    return h;
  }

  @override
  String toString() => 'PeerId(${shortPrefix()}...)';
}
