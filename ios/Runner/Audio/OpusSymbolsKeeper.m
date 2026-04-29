// Forces the iOS linker to keep all libopus symbols we need to call from
// Dart FFI via DynamicLibrary.process(). Without these explicit references
// the linker's dead-strip pass removes unreferenced symbols even when
// libopus.a is pulled in via -force_load — so the symbols exist in the .a
// but not in the final Runner binary, and dlsym(RTLD_DEFAULT, "opus_*")
// returns "symbol not found".
//
// We use an inline asm escape hatch — `asm volatile("" :: "r"(&opus_*))` —
// which forces the compiler to materialize the address of each opus_*
// function in a register and treats the asm block as having unknowable
// side effects. This survives every optimization level: the compiler
// must emit the relocation, the linker must resolve the symbol, the
// symbol ends up in the final binary.
//
// Used by Phase 3 mesh voice (lib/core/audio/opus/opus_bindings.dart).
// Called from AppDelegate.swift didFinishLaunching to ensure the function
// is reachable from main → not dead-stripped by the linker.

#import <opus/opus.h>

#define KEEP(sym) __asm__ __volatile__("" :: "r"(&(sym)))

void taler_force_keep_opus_symbols(void) {
    KEEP(opus_encoder_create);
    KEEP(opus_encode);
    KEEP(opus_encoder_destroy);
    KEEP(opus_decoder_create);
    KEEP(opus_decode);
    KEEP(opus_decoder_destroy);
    KEEP(opus_encoder_ctl);
    KEEP(opus_get_version_string);
}
