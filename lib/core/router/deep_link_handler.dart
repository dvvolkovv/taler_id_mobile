import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../utils/constants.dart';

/// Hosts whose OAuth links this app may act on. Mirrors the associated-domains
/// entitlement and the Android intent-filters; the OS will only ever deliver a
/// link from a host that vouches for this build in its assetlinks.json / AASA,
/// so this is a second line rather than the gate itself.
const _oauthHosts = {
  'id.taler.tirol',
  'staging.id.taler.tirol',
  'api.talerid.io',
  'talerid.io',
};

class DeepLinkHandler {
  static final _appLinks = AppLinks();

  // A cold start delivers the launching link twice — once from getInitialLink()
  // and again on the stream — which stacked two consent screens, so cancelling
  // one just revealed another.
  static Uri? _lastHandled;
  static DateTime? _lastHandledAt;
  static const _duplicateWindow = Duration(seconds: 3);

  static Future<void> init(GoRouter router) async {
    // Handle initial deep link (app opened via link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleUri(router, initialLink);
      }
    } catch (e) {
      debugPrint('Initial link error: $e');
    }

    // Handle subsequent deep links
    _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(router, uri),
      onError: (e) => debugPrint('Deep link error: $e'),
    );
  }

  static void _handleUri(GoRouter router, Uri uri) {
    debugPrint('Deep link received: $uri');

    if (isDuplicate(uri, DateTime.now())) {
      debugPrint('Deep link ignored: same link again within the startup window');
      return;
    }

    final target = resolve(uri);
    if (target == null) return;
    // OAuth is pushed so the flow can be backed out of, returning the user to
    // wherever they were; the rest replace the location.
    if (target.push) {
      router.push(target.location);
    } else {
      router.go(target.location);
    }
  }

  /// Whether this link was already acted on moments ago.
  ///
  /// Only collapses the cold-start double delivery: the same link opened again
  /// later is a deliberate act and must still work.
  @visibleForTesting
  static bool isDuplicate(Uri uri, DateTime now) {
    final last = _lastHandled;
    final at = _lastHandledAt;
    if (last == uri && at != null && now.difference(at) < _duplicateWindow) {
      return true;
    }
    _lastHandled = uri;
    _lastHandledAt = now;
    return false;
  }

  @visibleForTesting
  static void resetDuplicateGuard() {
    _lastHandled = null;
    _lastHandledAt = null;
  }

  /// Maps an incoming link to the in-app location it should open, or null when
  /// the app has nothing to do with it.
  static DeepLinkTarget? resolve(Uri uri) {
    // OAuth native login (Universal Links / App Links):
    // https://<host>/oauth/auth?...
    //
    // The path is the OIDC authorization endpoint, and it is matched exactly:
    // /oauth/auth/{uid} is where the browser consent page continues, so treating
    // this as a prefix would pull the user out of a flow they started in the
    // browser. This used to look for /oauth/authorize, which no environment has
    // ever served — so native login never once triggered.
    if (uri.path == '/oauth/auth' && _oauthHosts.contains(uri.host)) {
      final query = uri.query.isEmpty ? '' : '?${uri.query}';
      return DeepLinkTarget(
        '${RouteConstants.oauthAuthorize}$query',
        push: true,
      );
    }

    // Handle invite links:
    // https://id.taler.tirol/ui/invite.html?token=X
    // talerid://invite?token=X
    if (uri.path.contains('invite') || uri.host == 'invite') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        return DeepLinkTarget('/invite?token=$token');
      }
    }

    // Handle public room links:
    // https://id.taler.tirol/room/{code}
    if (uri.path.startsWith('/room/')) {
      final code = uri.pathSegments.last;
      if (code.isNotEmpty) {
        return DeepLinkTarget('/dashboard/voice?publicCode=$code');
      }
    }

    // Handle user profile links:
    // talerid://user/{userId}
    if (uri.scheme == 'talerid' &&
        uri.host == 'user' &&
        uri.pathSegments.isNotEmpty) {
      final userId = uri.pathSegments.first;
      if (userId.isNotEmpty) {
        return DeepLinkTarget('/dashboard/user/$userId');
      }
    }

    return null;
  }
}

class DeepLinkTarget {
  const DeepLinkTarget(this.location, {this.push = false});

  final String location;
  final bool push;

  @override
  String toString() => 'DeepLinkTarget($location, push: $push)';
}
