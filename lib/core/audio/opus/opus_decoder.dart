import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'opus_bindings.dart';

class OpusDecoder {
  final OpusBindings _b = OpusBindings.load();
  ffi.Pointer<ffi.Void>? _state;
  final int sampleRate;
  final int channels;

  OpusDecoder({required this.sampleRate, required this.channels}) {
    final err = calloc<ffi.Int32>();
    try {
      _state = _b.opusDecoderCreate(sampleRate, channels, err);
      if (err.value != opusOk || _state == ffi.nullptr) {
        throw StateError('opus_decoder_create failed: ${err.value}');
      }
    } finally {
      calloc.free(err);
    }
  }

  /// Decode an Opus packet. [frameSize] is the expected number of samples per channel.
  /// Pass an empty Uint8List with `useFec=false` to invoke Opus PLC (packet loss concealment).
  Int16List decode(Uint8List opus, {required int frameSize, bool useFec = false}) {
    final state = _state;
    if (state == null) throw StateError('OpusDecoder is disposed');

    final inPtr = calloc<ffi.Uint8>(opus.length == 0 ? 1 : opus.length);
    final outPtr = calloc<ffi.Int16>(frameSize * channels);
    try {
      if (opus.isNotEmpty) {
        inPtr.asTypedList(opus.length).setAll(0, opus);
      }
      final n = _b.opusDecode(
        state,
        opus.isEmpty ? ffi.nullptr : inPtr,
        opus.length,
        outPtr,
        frameSize,
        useFec ? 1 : 0,
      );
      if (n < 0) {
        throw StateError('opus_decode failed: $n');
      }
      return Int16List.fromList(outPtr.asTypedList(n * channels));
    } finally {
      calloc.free(inPtr);
      calloc.free(outPtr);
    }
  }

  void dispose() {
    final state = _state;
    if (state != null) {
      _b.opusDecoderDestroy(state);
      _state = null;
    }
  }
}
