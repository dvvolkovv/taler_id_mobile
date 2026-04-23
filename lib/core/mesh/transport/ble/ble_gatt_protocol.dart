import 'dart:typed_data';

/// Protocol constants + wire-format helpers for the BLE transport.
///
/// GATT surface is a single service with a single characteristic. The
/// characteristic supports `WRITE_WITHOUT_RESPONSE | NOTIFY`, giving us a
/// full-duplex byte channel over which Noise frames flow.
///
/// Each application-level Noise frame is prefixed by a 2-byte big-endian
/// length. Receivers reassemble over arbitrary chunk boundaries produced
/// by BLE MTU fragmentation.
class BleGattProtocol {
  /// 128-bit service UUID advertised by the peripheral role.
  static const String serviceUuid =
      '00005459-4c52-4944-4d45-534853470100';

  /// 128-bit characteristic UUID exposed under [serviceUuid].
  static const String characteristicUuid =
      '00005459-4c52-4944-4d45-534853470101';

  /// Maximum payload length for a single Noise frame over BLE. Aligned with
  /// the upper-layer `Frame.maxPayload` so we never truncate.
  static const int maxFrameLength = 65535;

  /// Wrap a Noise frame with a 2-byte big-endian length prefix.
  static Uint8List encodeFrame(Uint8List payload) {
    if (payload.length > maxFrameLength) {
      throw ArgumentError('BLE frame over $maxFrameLength bytes');
    }
    final out = Uint8List(2 + payload.length);
    out[0] = (payload.length >> 8) & 0xFF;
    out[1] = payload.length & 0xFF;
    out.setRange(2, out.length, payload);
    return out;
  }

  /// Split a prepared wire buffer into MTU-sized chunks for sequential
  /// write / notify operations.
  static List<Uint8List> chunkForMtu(Uint8List wire, {required int mtu}) {
    if (mtu < 1) {
      throw ArgumentError('mtu must be >= 1, got $mtu');
    }
    final out = <Uint8List>[];
    for (var i = 0; i < wire.length; i += mtu) {
      final end = (i + mtu < wire.length) ? i + mtu : wire.length;
      out.add(Uint8List.sublistView(wire, i, end));
    }
    return out;
  }
}

/// Stateful decoder for the opposite direction: fed arbitrary chunks,
/// invokes [onFrame] once per complete decoded Noise frame.
class FrameReassembler {
  final List<int> _buffer = [];
  void Function(Uint8List frame)? onFrame;

  void feed(Uint8List chunk) {
    _buffer.addAll(chunk);
    while (_tryExtract()) {}
  }

  bool _tryExtract() {
    if (_buffer.length < 2) return false;
    final len = (_buffer[0] << 8) | _buffer[1];
    if (len == 0 || len > BleGattProtocol.maxFrameLength) {
      // Malformed — drop everything; the peer is out of sync.
      _buffer.clear();
      return false;
    }
    if (_buffer.length < 2 + len) return false;
    final frame = Uint8List.fromList(_buffer.sublist(2, 2 + len));
    _buffer.removeRange(0, 2 + len);
    onFrame?.call(frame);
    return true;
  }
}
