// lib/core/platform/oauth_callback.dart
import 'package:flutter/foundation.dart';
import 'platform_utils.dart';
import 'oauth_callback_mobile.dart';
import 'oauth_callback_desktop.dart';

/// Result returned from [OAuthCallbackPlatform.startFlow].
class OAuthCallbackResult {
  final String? code;
  final String? state;

  /// The redirect_uri that was used in the authorization request.
  /// On desktop: `http://127.0.0.1:<port>/cb`
  /// On mobile: not meaningful (Universal Links handle delivery outside this abstraction).
  final String? redirectUri;
  final String? error;

  const OAuthCallbackResult({this.code, this.state, this.redirectUri, this.error});

  factory OAuthCallbackResult.success(
    String code, {
    String? state,
    String? redirectUri,
  }) =>
      OAuthCallbackResult(code: code, state: state, redirectUri: redirectUri);

  factory OAuthCallbackResult.errorResult(String reason) =>
      OAuthCallbackResult(error: reason);

  bool get isSuccess => code != null;
}

/// Platform-agnostic interface for initiating an OAuth 2.0 authorization code flow.
///
/// Mobile (iOS, Android) → [OAuthCallbackMobile]
///   Uses Universal Links / App Links; the system browser redirects back to the
///   app via the registered AASA/assetlinks entry. The existing [DeepLinkHandler]
///   + [OAuthAuthorizeScreen] flow handles everything — this abstraction is a no-op
///   on mobile (throws [UnimplementedError] if actually called).
///
/// Desktop (macOS, Windows, Linux) → [OAuthCallbackDesktop]
///   Follows RFC 8252 §7.3: binds an ephemeral HTTP server on 127.0.0.1, opens the
///   system browser with `redirect_uri=http://127.0.0.1:<port>/cb`, and captures
///   the authorization code when the browser redirects back.
///
/// Use [debugResetForTest] / [debugInstance] in unit tests to inject a fake.
abstract class OAuthCallbackPlatform {
  static OAuthCallbackPlatform? _instance;

  static OAuthCallbackPlatform get instance =>
      _instance ??= PlatformUtils.instance.isMobile
          ? OAuthCallbackMobile()
          : OAuthCallbackDesktop();

  /// Initiates the OAuth authorization code flow.
  ///
  /// Opens the system browser at [authorizationEndpoint] with the required
  /// query parameters. On desktop, captures the callback via an ephemeral
  /// loopback HTTP server; on mobile this method is not used (see class docs).
  ///
  /// Returns an [OAuthCallbackResult] with either [code] (success) or [error].
  Future<OAuthCallbackResult> startFlow({
    required String authorizationEndpoint,
    required String clientId,
    required String scope,
    required String state,
  });

  @visibleForTesting
  static void debugResetForTest() => _instance = null;

  @visibleForTesting
  static set debugInstance(OAuthCallbackPlatform i) => _instance = i;
}
