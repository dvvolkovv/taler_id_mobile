import 'dart:typed_data';

enum JitterFrameKind { payload, plc, silence }

class JitterFrame {
  final JitterFrameKind kind;
  final Uint8List? payload; // null when kind != payload
  JitterFrame.payload(Uint8List p)
      : kind = JitterFrameKind.payload,
        payload = p;
  JitterFrame.plc()
      : kind = JitterFrameKind.plc,
        payload = null;
  JitterFrame.silence()
      : kind = JitterFrameKind.silence,
        payload = null;
}

class JitterBuffer {
  final int targetDepthFrames;
  final Map<int, Uint8List> _entries = {};
  int? _nextPlayoutSeq;

  JitterBuffer({this.targetDepthFrames = 4});

  void push({required int seq, required Uint8List payload}) {
    final next = _nextPlayoutSeq;
    if (next != null && seq < next) {
      // Late frame — drop.
      return;
    }
    _entries[seq] = payload;
  }

  /// Pull the next frame to play, or null if buffer empty.
  /// On a gap, returns a PLC frame for each missing seq.
  JitterFrame? pull() {
    if (_entries.isEmpty && _nextPlayoutSeq == null) return null;

    if (_nextPlayoutSeq == null) {
      // First pull — start at the smallest seq we have.
      _nextPlayoutSeq = _entries.keys.reduce((a, b) => a < b ? a : b);
    }

    final seq = _nextPlayoutSeq!;
    final entry = _entries.remove(seq);
    _nextPlayoutSeq = seq + 1;

    if (entry != null) {
      return JitterFrame.payload(entry);
    }
    // Gap — emit PLC and advance.
    return JitterFrame.plc();
  }

  int get bufferedFrames => _entries.length;
}
