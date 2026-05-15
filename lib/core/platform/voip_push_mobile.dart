// lib/core/platform/voip_push_mobile.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'voip_push.dart';
import 'call_kit.dart';

/// Mobile implementation of [VoipPushPlatform].
///
/// VoIP token retrieval delegates to [CallKitPlatform.instance] which wraps
/// `flutter_callkit_incoming`'s [FlutterCallkitIncoming.getDevicePushTokenVoIP]
/// on iOS.  On Android, CallKit returns null (FCM data-only messages handle
/// call_invite delivery instead).
///
/// [incomingPayloads] re-maps the
/// [CallKitEvent.typePushTokenVoip] events from the shared CallKit stream so
/// that higher-level code can react to token refresh without importing
/// flutter_callkit_incoming directly.
class VoipPushMobile implements VoipPushPlatform {
  @override
  Future<String?> getToken() async {
    try {
      return await CallKitPlatform.instance.getDevicePushTokenVoIP();
    } catch (e) {
      debugPrint('[VoipPushMobile] getToken failed: $e');
      return null;
    }
  }

  @override
  Stream<Map<String, dynamic>> get incomingPayloads {
    // The CallKit event stream re-broadcasts all native events including
    // DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP which carries the token in event.data.
    return CallKitPlatform.instance.events
        .where((e) => e.type == CallKitEvent.typePushTokenVoip)
        .map((e) => Map<String, dynamic>.from(e.data ?? <String, dynamic>{}));
  }
}
