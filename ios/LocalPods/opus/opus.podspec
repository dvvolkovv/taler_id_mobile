Pod::Spec.new do |s|
  s.name             = 'opus'
  s.version          = '1.4'
  s.summary          = 'libopus 1.4 static library for iOS (arm64). Used by mesh voice calls (Phase 3).'
  s.description      = 'Compiled from opus 1.4 official source. BSD-3-Clause license.'
  s.homepage         = 'https://opus-codec.org'
  s.license          = { :type => 'BSD-3-Clause', :file => 'LICENSE' }
  s.author           = { 'Xiph.Org' => 'opus@xiph.org' }
  s.platform         = :ios, '13.0'
  s.source           = { :path => '.' }
  # Static library — symbols are merged into the app binary.
  # Dart DynamicLibrary.process() can find them via RTLD_DEFAULT.
  s.vendored_libraries = 'libs/libopus.a'
  s.public_header_files = 'include/*.h'
  s.source_files     = 'include/*.h'
  # -force_load prevents the linker from stripping unreferenced opus symbols.
  # Required so Dart FFI can find them via DynamicLibrary.process().
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-force_load "$(PODS_TARGET_SRCROOT)/libs/libopus.a"' }
  # -force_load brings the libopus .o files into the binary.
  # -u keeps the `taler_opus_*` wrappers (defined in Runner/Audio/OpusSymbolsKeeper.m)
  #   alive through linker dead-strip — required because Runner is built with
  #   GCC_SYMBOLS_PRIVATE_EXTERN=YES + DEAD_CODE_STRIPPING=YES, which would otherwise
  #   drop them since nothing in the rest of Runner references them.
  # -exported_symbol then keeps the wrapper names in the Mach-O export trie so
  #   `dlsym(RTLD_DEFAULT, "taler_opus_*")` from Dart FFI can resolve them.
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => [
      '-force_load "$(PODS_ROOT)/../LocalPods/opus/libs/libopus.a"',
      '-Wl,-u,_taler_opus_encoder_create',
      '-Wl,-u,_taler_opus_encode',
      '-Wl,-u,_taler_opus_encoder_destroy',
      '-Wl,-u,_taler_opus_decoder_create',
      '-Wl,-u,_taler_opus_decode',
      '-Wl,-u,_taler_opus_decoder_destroy',
      '-Wl,-u,_taler_opus_encoder_ctl_int',
      '-Wl,-u,_taler_opus_get_version_string',
      '-Wl,-exported_symbol,_taler_opus_encoder_create',
      '-Wl,-exported_symbol,_taler_opus_encode',
      '-Wl,-exported_symbol,_taler_opus_encoder_destroy',
      '-Wl,-exported_symbol,_taler_opus_decoder_create',
      '-Wl,-exported_symbol,_taler_opus_decode',
      '-Wl,-exported_symbol,_taler_opus_decoder_destroy',
      '-Wl,-exported_symbol,_taler_opus_encoder_ctl_int',
      '-Wl,-exported_symbol,_taler_opus_get_version_string',
    ].join(' '),
  }
  # Ensure it's treated as a static library (not dynamic framework)
  s.static_framework = true
end
