import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';

/// Opus C API constants (from `opus_defines.h`).
const int opusOk = 0;
const int opusApplicationVoip = 2048;
const int opusSetBitrateRequest = 4002;
const int opusSetInbandFecRequest = 4012;

typedef _OpusEncoderCreateNative = ffi.Pointer<ffi.Void> Function(
    ffi.Int32 sampleRate,
    ffi.Int32 channels,
    ffi.Int32 application,
    ffi.Pointer<ffi.Int32> error);
typedef OpusEncoderCreate = ffi.Pointer<ffi.Void> Function(
    int sampleRate, int channels, int application, ffi.Pointer<ffi.Int32> error);

typedef _OpusEncodeNative = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> st,
    ffi.Pointer<ffi.Int16> pcm,
    ffi.Int32 frameSize,
    ffi.Pointer<ffi.Uint8> data,
    ffi.Int32 maxDataBytes);
typedef OpusEncode = int Function(ffi.Pointer<ffi.Void> st,
    ffi.Pointer<ffi.Int16> pcm, int frameSize, ffi.Pointer<ffi.Uint8> data, int maxDataBytes);

typedef _OpusEncoderDestroyNative = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef OpusEncoderDestroy = void Function(ffi.Pointer<ffi.Void>);

typedef _OpusDecoderCreateNative = ffi.Pointer<ffi.Void> Function(
    ffi.Int32 sampleRate, ffi.Int32 channels, ffi.Pointer<ffi.Int32> error);
typedef OpusDecoderCreate = ffi.Pointer<ffi.Void> Function(
    int sampleRate, int channels, ffi.Pointer<ffi.Int32> error);

typedef _OpusDecodeNative = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> st,
    ffi.Pointer<ffi.Uint8> data,
    ffi.Int32 len,
    ffi.Pointer<ffi.Int16> pcm,
    ffi.Int32 frameSize,
    ffi.Int32 decodeFec);
typedef OpusDecode = int Function(ffi.Pointer<ffi.Void> st,
    ffi.Pointer<ffi.Uint8> data, int len, ffi.Pointer<ffi.Int16> pcm, int frameSize, int decodeFec);

typedef _OpusDecoderDestroyNative = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef OpusDecoderDestroy = void Function(ffi.Pointer<ffi.Void>);

// opus_encoder_ctl is variadic in C: `int opus_encoder_ctl(OpusEncoder*, int, ...)`.
// On iOS arm64 the calling convention for variadic args differs from regular
// args (variadic args go on the stack with specific alignment, not in scalar
// registers like AAPCS64 does for fixed args). We MUST declare the int value
// as a VarArgs argument so dart:ffi emits the correct ABI; otherwise the
// passed bitrate is read from the wrong location and opus_encoder_ctl
// returns OPUS_BAD_ARG (-1).
typedef _OpusEncoderCtlNative = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> st,
    ffi.Int32 request,
    ffi.VarArgs<(ffi.Int32,)>);
typedef OpusEncoderCtl = int Function(ffi.Pointer<ffi.Void> st, int request, int value);

class OpusBindings {
  static OpusBindings? _instance;

  final ffi.DynamicLibrary _lib;
  final OpusEncoderCreate opusEncoderCreate;
  final OpusEncode opusEncode;
  final OpusEncoderDestroy opusEncoderDestroy;
  final OpusDecoderCreate opusDecoderCreate;
  final OpusDecode opusDecode;
  final OpusDecoderDestroy opusDecoderDestroy;
  final OpusEncoderCtl opusEncoderCtl;

  OpusBindings._(this._lib)
      : opusEncoderCreate = _lib.lookupFunction<_OpusEncoderCreateNative, OpusEncoderCreate>('opus_encoder_create'),
        opusEncode = _lib.lookupFunction<_OpusEncodeNative, OpusEncode>('opus_encode'),
        opusEncoderDestroy = _lib.lookupFunction<_OpusEncoderDestroyNative, OpusEncoderDestroy>('opus_encoder_destroy'),
        opusDecoderCreate = _lib.lookupFunction<_OpusDecoderCreateNative, OpusDecoderCreate>('opus_decoder_create'),
        opusDecode = _lib.lookupFunction<_OpusDecodeNative, OpusDecode>('opus_decode'),
        opusDecoderDestroy = _lib.lookupFunction<_OpusDecoderDestroyNative, OpusDecoderDestroy>('opus_decoder_destroy'),
        opusEncoderCtl = _lib.lookupFunction<_OpusEncoderCtlNative, OpusEncoderCtl>('opus_encoder_ctl');

  factory OpusBindings.load() {
    if (_instance != null) return _instance!;
    final lib = Platform.isIOS
        ? ffi.DynamicLibrary.process()
        : ffi.DynamicLibrary.open('libopus.so');
    return _instance = OpusBindings._(lib);
  }
}
