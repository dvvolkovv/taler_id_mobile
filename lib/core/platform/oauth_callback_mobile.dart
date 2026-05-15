// lib/core/platform/oauth_callback_mobile.dart
import 'oauth_callback.dart';

/// Mobile stub for [OAuthCallbackPlatform].
///
/// On mobile (iOS / Android) the OAuth authorization code flow is handled
/// entirely via Universal Links / Android App Links:
///
///   1. The client (third-party app / web SPA) redirects the system browser to
///      `https://id.taler.tirol/oauth/authorize?...`
///   2. The OS intercepts the URL and launches Taler ID directly.
///   3. [DeepLinkHandler] routes it to [OAuthAuthorizeScreen], which presents
///      the consent UI and calls [OAuthRepository.approve].
///   4. The backend redirects the browser to the client's `redirect_uri` with
///      the authorization code.
///
/// This class is never actually called on mobile — [OAuthCallbackPlatform.instance]
/// returns it only as the dispatch target; real call sites on mobile bypass the
/// abstraction entirely (they are driven by incoming deep links, not by calling
/// [startFlow] proactively). Throwing [UnimplementedError] here makes any
/// accidental call visible immediately during development.
class OAuthCallbackMobile implements OAuthCallbackPlatform {
  @override
  Future<OAuthCallbackResult> startFlow({
    required String authorizationEndpoint,
    required String clientId,
    required String scope,
    required String state,
  }) {
    throw UnimplementedError(
      'OAuthCallbackMobile.startFlow is not implemented. '
      'On mobile, the OAuth flow is driven by incoming Universal Links handled by '
      'DeepLinkHandler → OAuthAuthorizeScreen. Call OAuthCallbackPlatform.instance.startFlow() '
      'only from desktop code paths.',
    );
  }
}
