import 'dart:io';
import 'package:flutter/services.dart';

/// Donates conversation intents to iOS so contacts appear in the share sheet.
class ShareSuggestionsService {
  static const _channel = MethodChannel('taler_id/share_suggestions');

  /// Call after sending/receiving a message to make this conversation
  /// appear in the iOS share sheet suggestions.
  static Future<void> donateConversation({
    required String conversationId,
    required String displayName,
    String? avatarUrl,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('donateConversation', {
        'conversationId': conversationId,
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });
    } catch (_) {
      // Non-critical — silently ignore
    }
  }
}
