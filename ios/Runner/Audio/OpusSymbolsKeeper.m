// Exported wrappers around libopus functions for Dart FFI.
//
// Why wrappers: iOS app binaries are stripped to an empty export trie by
// default — `dlsym(RTLD_DEFAULT, "opus_encoder_create")` returns NULL even
// when libopus.a is force_loaded into Runner. The opus_* functions are
// compiled into the binary (the code is there) but their names are removed
// from the symbol table.
//
// `__attribute__((used, visibility("default")))` on a wrapper does two
// things at once:
//   1. `used` — the compiler marks the function as referenced, preventing
//      dead-strip from removing it.
//   2. `visibility("default")` — the linker emits the symbol into the
//      Mach-O export trie, where dlsym(RTLD_DEFAULT, ...) can find it.
//
// Each wrapper is a thin call-through; the calling convention matches the
// underlying opus_* function exactly (including variadic for opus_encoder_ctl).
// Dart FFI looks up the `taler_opus_*` names via DynamicLibrary.process().

#import <opus/opus.h>

#define EXPORT __attribute__((used, visibility("default")))

EXPORT OpusEncoder* taler_opus_encoder_create(opus_int32 fs, int channels, int application, int* error) {
    return opus_encoder_create(fs, channels, application, error);
}

EXPORT opus_int32 taler_opus_encode(OpusEncoder* st, const opus_int16* pcm, int frame_size, unsigned char* data, opus_int32 max_data_bytes) {
    return opus_encode(st, pcm, frame_size, data, max_data_bytes);
}

EXPORT void taler_opus_encoder_destroy(OpusEncoder* st) {
    opus_encoder_destroy(st);
}

EXPORT OpusDecoder* taler_opus_decoder_create(opus_int32 fs, int channels, int* error) {
    return opus_decoder_create(fs, channels, error);
}

EXPORT int taler_opus_decode(OpusDecoder* st, const unsigned char* data, opus_int32 len, opus_int16* pcm, int frame_size, int decode_fec) {
    return opus_decode(st, data, len, pcm, frame_size, decode_fec);
}

EXPORT void taler_opus_decoder_destroy(OpusDecoder* st) {
    opus_decoder_destroy(st);
}

// opus_encoder_ctl is variadic; we only use the int form (set bitrate, FEC, etc.).
EXPORT int taler_opus_encoder_ctl_int(OpusEncoder* st, int request, opus_int32 value) {
    return opus_encoder_ctl(st, request, value);
}

EXPORT const char* taler_opus_get_version_string(void) {
    return opus_get_version_string();
}
