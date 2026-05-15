import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:taler_id_mobile/core/platform/platform_utils.dart';
import 'package:taler_id_mobile/core/router/app_router.dart';
import 'url_scheme_paths.dart';

class UrlSchemeHandler {
  static final UrlSchemeHandler instance = UrlSchemeHandler._();
  UrlSchemeHandler._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> initialize() async {
    if (!PlatformUtils.instance.isDesktop) return;
    // Cold-start link
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);
    // Live links while app is running
    _sub = _appLinks.uriLinkStream.listen(_handle);
  }

  void _handle(Uri uri) {
    final route = UrlSchemePaths.translate(uri);
    if (route != null) appRouter.go(route);
  }
}
