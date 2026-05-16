/// Maps notification payload strings to GoRouter paths.
///
/// Payload format: `<type>:<id>` where type is one of:
///   - `chat`          → `/dashboard/messenger/chat/<id>`
///   - `call`          → `/dashboard/call-history`
///   - `oauth-consent` → `/oauth/consent/<id>`
///   - `profile`       → `/dashboard/profile/<id>`
class NotificationRouting {
  NotificationRouting._();

  static String? routeFor(String payload) {
    final colon = payload.indexOf(':');
    if (colon < 0) return null;
    final type = payload.substring(0, colon);
    final id = payload.substring(colon + 1);
    switch (type) {
      case 'chat':
        return '/dashboard/messenger/chat/$id';
      case 'call':
        return '/dashboard/call-history';
      case 'oauth-consent':
        return '/oauth/consent/$id';
      case 'profile':
        return '/dashboard/profile/$id';
      default:
        return null;
    }
  }
}
