// lib/core/platform/callkit_support.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Whether the app runs in the iOS Simulator, which has no CallKit.
bool get isIosSimulator =>
    !kIsWeb &&
    Platform.isIOS &&
    (Platform.environment['SIMULATOR_DEVICE_NAME'] != null ||
        Platform.environment['SIMULATOR_UDID'] != null);

/// Extract UUID part from roomName like "call-550e8400-e29b-41d4-a716-446655440000"
/// CallKit requires a valid RFC4122 UUID string as id.
///
/// Contract:
/// - Case is kept as given; compare ids lowercased.
/// - `ios/Runner/AppDelegate.swift` (VoIP push path) mirrors only the plain-UUID
///   and `call-<uuid>` branches — change them together.
/// - For other rooms reported by a VoIP push, the CallKit id is the push's own
///   id, not `toCallkitId(roomName)`.
/// - The fallback relies on `String.hashCode` being unseeded (identical in every
///   isolate); never switch it to `Object.hash`.
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
