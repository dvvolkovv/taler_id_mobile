import 'package:freezed_annotation/freezed_annotation.dart';

part 'captured_notification.freezed.dart';
part 'captured_notification.g.dart';

/// Dart-side snapshot of a notification captured by the Android listener service.
///
/// Phase 1A — see docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md
///
/// Mirrors the Kotlin `CapturedNotification.toMap()` shape that the
/// `taler_id/notifications/cmd` MethodChannel and `taler_id/notifications/stream`
/// EventChannel emit.
@freezed
class CapturedNotification with _$CapturedNotification {
  const CapturedNotification._();

  const factory CapturedNotification({
    required String packageName,
    required String key,
    required DateTime postedAt,
    required String title,
    required String body,
    String? conversationTitle,
    @Default(false) bool canReply,
  }) = _CapturedNotification;

  factory CapturedNotification.fromJson(Map<String, dynamic> json) =>
      _$CapturedNotificationFromJson(json);

  /// Decode the platform-channel map (`postTimeMs` is int millis since epoch).
  factory CapturedNotification.fromMap(Map<dynamic, dynamic> map) {
    final postMs = (map['postTimeMs'] as num?)?.toInt() ?? 0;
    return CapturedNotification(
      packageName: (map['packageName'] as String?) ?? '',
      key: (map['key'] as String?) ?? '',
      postedAt: DateTime.fromMillisecondsSinceEpoch(postMs),
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      conversationTitle: map['conversationTitle'] as String?,
      canReply: (map['canReply'] as bool?) ?? false,
    );
  }

  /// Slim JSON shape passed back to the OpenAI Realtime tool output.
  Map<String, dynamic> toToolJson() => {
        'key': key,
        'app': packageName,
        'title': title,
        'body': body,
        if (conversationTitle != null) 'conversation': conversationTitle,
        'posted_at': postedAt.toUtc().toIso8601String(),
        'can_reply': canReply,
      };
}
