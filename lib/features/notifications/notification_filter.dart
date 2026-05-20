/// Query filter for [NotificationStore.recent].
///
/// Plain value type (no Freezed needed — four scalars, all optional). All fields
/// are passed verbatim to the native side via the `getRecent` MethodChannel
/// call. Null fields mean "don't filter on this dimension".
class NotificationFilter {
  /// Substring matched against `packageName` (case-insensitive on the native
  /// side; we also lower-case here for the Dart-side cache fallback path).
  /// e.g. `"whatsapp"`, `"telegram"`, `"gmail"`.
  final String? app;

  /// Substring matched against `conversationTitle` or `title`.
  /// e.g. `"Маша"`.
  final String? sender;

  /// Only items posted within the last N minutes.
  final int? sinceMinutes;

  /// Max items returned (native side defaults to 50 if null).
  final int? limit;

  const NotificationFilter({
    this.app,
    this.sender,
    this.sinceMinutes,
    this.limit,
  });

  static const empty = NotificationFilter();

  Map<String, dynamic> toMethodArgs() => {
        if (app != null) 'app': app,
        if (sender != null) 'sender': sender,
        if (sinceMinutes != null) 'sinceMinutes': sinceMinutes,
        if (limit != null) 'limit': limit,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationFilter &&
          other.app == app &&
          other.sender == sender &&
          other.sinceMinutes == sinceMinutes &&
          other.limit == limit;

  @override
  int get hashCode => Object.hash(app, sender, sinceMinutes, limit);

  @override
  String toString() =>
      'NotificationFilter(app: $app, sender: $sender, '
      'sinceMinutes: $sinceMinutes, limit: $limit)';
}
