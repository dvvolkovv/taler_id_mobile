import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class DeepLinkHandler {
  static final _appLinks = AppLinks();

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

    // OAuth native login (Universal Links / App Links):
    // https://id.taler.tirol/oauth/authorize?...
    // https://staging.id.taler.tirol/oauth/authorize?...
    if (uri.path == '/oauth/authorize' &&
        (uri.host == 'id.taler.tirol' || uri.host == 'staging.id.taler.tirol' || uri.host == 'talerid.io')) {
      final query = uri.query.isEmpty ? '' : '?${uri.query}';
      router.push('/oauth/authorize$query');
      return;
    }

    // Handle invite links:
    // https://id.taler.tirol/ui/invite.html?token=X
    // talerid://invite?token=X
    if (uri.path.contains('invite') || uri.host == 'invite') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        router.go('/invite?token=$token');
        return;
      }
    }

    // Handle public room links:
    // https://id.taler.tirol/room/{code}
    if (uri.path.startsWith('/room/')) {
      final code = uri.pathSegments.last;
      if (code.isNotEmpty) {
        router.go('/dashboard/voice?publicCode=$code');
        return;
      }
    }

    // Handle user profile links:
    // talerid://user/{userId}
    if (uri.scheme == 'talerid' && uri.host == 'user' && uri.pathSegments.isNotEmpty) {
      final userId = uri.pathSegments.first;
      if (userId.isNotEmpty) {
        router.go('/dashboard/user/$userId');
        return;
      }
    }
  }
}
