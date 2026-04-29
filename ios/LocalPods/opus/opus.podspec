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
  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '-force_load "$(PODS_ROOT)/../LocalPods/opus/libs/libopus.a"' }
  # Ensure it's treated as a static library (not dynamic framework)
  s.static_framework = true
end
