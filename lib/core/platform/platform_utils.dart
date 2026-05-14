// lib/core/platform/platform_utils.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtils {
  PlatformUtils._();
  static final PlatformUtils instance = PlatformUtils._();

  bool get isWeb => kIsWeb;
  bool get isMobile => !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  bool get isMacOS => !kIsWeb && Platform.isMacOS;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isLinux => !kIsWeb && Platform.isLinux;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  bool get supportsCallKit => isMobile;
  bool get supportsFirebase => isMobile;
  bool get supportsSumsubSdk => isMobile;
  bool get supportsMesh => isMobile;
  bool get supportsBiometric => isMobile || isMacOS;

  String get hostOs {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
