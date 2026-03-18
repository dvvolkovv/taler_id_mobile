import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

bool get isWebPlatform => kIsWeb;

bool get isMobilePlatform =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid);

bool get isDesktopPlatform =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

bool get supportsCallKit => isMobilePlatform;

bool get supportsFirebase => isMobilePlatform;

bool get supportsBiometric =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS);

bool get supportsSumsubSdk => isMobilePlatform;
