/// Mapping of `talerid://<host>/<path>` URIs to in-app go_router paths.
///
/// Linux note: URL scheme registration on Linux requires manual setup —
/// run `xdg-mime default taler_id_mobile.desktop x-scheme-handler/talerid`
/// once per user, or include the .desktop file in the tar.gz distribution.
class UrlSchemePaths {
  UrlSchemePaths._();

  /// Translates a parsed [Uri] (e.g., `talerid://chat/abc-123`) into an
  /// in-app go_router path (e.g., `/dashboard/messenger/abc-123`).
  /// Returns null if the URI is unrecognised.
  static String? translate(Uri uri) {
    if (uri.scheme != 'talerid') return null;
    final segments = uri.pathSegments;
    final host = uri.host;

    // talerid://oauth-callback?code=...&state=...
    if (host == 'oauth-callback') {
      return '/oauth/desktop-callback?${uri.query}';
    }
    // talerid://chat/<id>
    if (host == 'chat' && segments.length == 1) {
      return '/dashboard/messenger/${segments[0]}';
    }
    // talerid://profile/<id>
    if (host == 'profile' && segments.length == 1) {
      return '/dashboard/user/${segments[0]}';
    }
    // talerid://calendar
    if (host == 'calendar') {
      return '/dashboard/calendar';
    }
    // talerid://assistant
    if (host == 'assistant') {
      return '/dashboard/assistant';
    }
    return null;
  }
}
