import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// The iOS Simulator has no CallKit.
bool get isIosSimulator =>
    !kIsWeb &&
    Platform.isIOS &&
    (Platform.environment['SIMULATOR_DEVICE_NAME'] != null ||
        Platform.environment['SIMULATOR_UDID'] != null);

/// Extract UUID part from roomName like "call-550e8400-e29b-41d4-a716-446655440000"
/// CallKit requires a valid RFC4122 UUID string as id.
String toCallkitId(String roomName) {
  // If roomName already looks like a UUID, use it directly
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  if (uuidRegex.hasMatch(roomName)) return roomName;
  // Strip prefix "call-" and take remaining UUID part
  final stripped = roomName.replaceFirst(RegExp(r'^call-'), '');
  if (uuidRegex.hasMatch(stripped)) return stripped;
  // Fallback: derive UUID from hash (must be a valid UUID)
  final hash = roomName.hashCode.abs();
  return '00000000-0000-4000-8000-${hash.toRadixString(16).padLeft(12, '0').substring(0, 12)}';
}
