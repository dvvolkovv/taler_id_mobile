import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'opus_bindings.dart';

class OpusEncoder {
  final OpusBindings _b = OpusBindings.load();
  ffi.Pointer<ffi.Void>? _state;
  final int sampleRate;
  final int channels;

  OpusEncoder({
    required this.sampleRate,
    required this.channels,
    required int bitrate,
    int application = opusApplicationVoip,
  }) {
    final err = calloc<ffi.Int32>();
    try {
      _state = _b.opusEncoderCreate(sampleRate, channels, application, err);
      if (err.value != opusOk || _state == ffi.nullptr) {
        throw StateError('opus_encoder_create failed: ${err.value}');
      }
      // Set target bitrate.
      final ctlRes = _b.opusEncoderCtl(_state!, opusSetBitrateRequest, bitrate);
      if (ctlRes != opusOk) {
        throw StateError('opus_encoder_ctl(set_bitrate) failed: $ctlRes');
      }
    } finally {
      calloc.free(err);
    }
  }

  /// Encode a single PCM frame. [pcm] must have length = sampleRate * frameMs / 1000 * channels.
  /// Returns the encoded Opus bytes.
  Uint8List encode(Int16List pcm) {
    final state = _state;
    if (state == null) throw StateError('OpusEncoder is disposed');

    final pcmPtr = calloc<ffi.Int16>(pcm.length);
    final outPtr = calloc<ffi.Uint8>(4000); // generous upper bound
    try {
      final pcmList = pcmPtr.asTypedList(pcm.length);
      pcmList.setAll(0, pcm);

      final n = _b.opusEncode(state, pcmPtr, pcm.length, outPtr, 4000);
      if (n < 0) {
        throw StateError('opus_encode failed: $n');
      }
      return Uint8List.fromList(outPtr.asTypedList(n));
    } finally {
      calloc.free(pcmPtr);
      calloc.free(outPtr);
    }
  }

  void dispose() {
    final state = _state;
    if (state != null) {
      _b.opusEncoderDestroy(state);
      _state = null;
    }
  }
}
