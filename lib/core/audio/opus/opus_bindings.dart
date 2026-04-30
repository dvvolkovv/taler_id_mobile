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
typedef _OpusEncoderCtlNativeVar = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> st,
    ffi.Int32 request,
    ffi.VarArgs<(ffi.Int32,)>);
// iOS wrapper `taler_opus_encoder_ctl_int` is non-variadic — its signature is
// (state, request, int_value) with all args fixed. Dart binding must match.
typedef _OpusEncoderCtlNativeFixed = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> st, ffi.Int32 request, ffi.Int32 value);
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

  OpusBindings._(this._lib, {required bool useIosWrappers})
      : opusEncoderCreate = _lib.lookupFunction<_OpusEncoderCreateNative, OpusEncoderCreate>(
            useIosWrappers ? 'taler_opus_encoder_create' : 'opus_encoder_create'),
        opusEncode = _lib.lookupFunction<_OpusEncodeNative, OpusEncode>(
            useIosWrappers ? 'taler_opus_encode' : 'opus_encode'),
        opusEncoderDestroy = _lib.lookupFunction<_OpusEncoderDestroyNative, OpusEncoderDestroy>(
            useIosWrappers ? 'taler_opus_encoder_destroy' : 'opus_encoder_destroy'),
        opusDecoderCreate = _lib.lookupFunction<_OpusDecoderCreateNative, OpusDecoderCreate>(
            useIosWrappers ? 'taler_opus_decoder_create' : 'opus_decoder_create'),
        opusDecode = _lib.lookupFunction<_OpusDecodeNative, OpusDecode>(
            useIosWrappers ? 'taler_opus_decode' : 'opus_decode'),
        opusDecoderDestroy = _lib.lookupFunction<_OpusDecoderDestroyNative, OpusDecoderDestroy>(
            useIosWrappers ? 'taler_opus_decoder_destroy' : 'opus_decoder_destroy'),
        opusEncoderCtl = useIosWrappers
            ? _lib.lookupFunction<_OpusEncoderCtlNativeFixed, OpusEncoderCtl>('taler_opus_encoder_ctl_int')
            : _lib.lookupFunction<_OpusEncoderCtlNativeVar, OpusEncoderCtl>('opus_encoder_ctl');

  factory OpusBindings.load() {
    if (_instance != null) return _instance!;
    final lib = Platform.isIOS
        ? ffi.DynamicLibrary.process()
        : ffi.DynamicLibrary.open('libopus.so');
    // On iOS the libopus symbols are not in the export trie of the stripped
    // app binary. We export Objective-C wrappers (`taler_opus_*`) from
    // OpusSymbolsKeeper.m which dlsym CAN find. On Android we look up the
    // raw opus_* names from the .so (.so exports work normally there).
    return _instance = OpusBindings._(lib, useIosWrappers: Platform.isIOS);
  }
}
