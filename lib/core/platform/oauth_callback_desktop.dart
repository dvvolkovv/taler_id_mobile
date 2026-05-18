// lib/core/platform/oauth_callback_desktop.dart
import 'package:url_launcher/url_launcher.dart';
import 'package:taler_id_mobile/features/oauth/desktop/oauth_loopback_server.dart';
import 'oauth_callback.dart';

/// Desktop implementation of [OAuthCallbackPlatform] using RFC 8252 §7.3
/// loopback redirect URIs.
///
/// Flow:
/// 1. Binds [OAuthLoopbackServer] to an ephemeral 127.0.0.1 port.
/// 2. Opens the system browser with redirect_uri=http://127.0.0.1:<port>/cb.
/// 3. Waits (up to 5 min) for the browser to redirect back with ?code=...
/// 4. Returns [OAuthCallbackResult.success] or [OAuthCallbackResult.errorResult].
class OAuthCallbackDesktop implements OAuthCallbackPlatform {
  @override
  Future<OAuthCallbackResult> startFlow({
    required String authorizationEndpoint,
    required String clientId,
    required String scope,
    required String state,
  }) async {
    final server = OAuthLoopbackServer();

    // Start awaiting the callback before opening the browser so the server is
    // already listening when the browser redirects back.
    final callbackFuture = server.awaitCallback();

    // Give the server a moment to bind and populate its port.
    await Future.delayed(const Duration(milliseconds: 50));

    final redirectUri = server.redirectUri;
    if (redirectUri == null) {
      return OAuthCallbackResult.errorResult('Не удалось открыть локальный порт');
    }

    final authUrl = Uri.parse(authorizationEndpoint).replace(queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scope,
      'state': state,
    });

    final launched = await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    if (!launched) {
      return OAuthCallbackResult.errorResult('Не удалось открыть браузер');
    }

    final loopbackResult = await callbackFuture;
    if (loopbackResult.isSuccess) {
      return OAuthCallbackResult.success(
        loopbackResult.code!,
        state: loopbackResult.state,
        redirectUri: redirectUri,
      );
    }
    return OAuthCallbackResult.errorResult(loopbackResult.error ?? 'unknown');
  }
}
