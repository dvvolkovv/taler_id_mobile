import 'package:freezed_annotation/freezed_annotation.dart';

part 'oauth_authorize_params.freezed.dart';

@freezed
class OAuthAuthorizeParams with _$OAuthAuthorizeParams {
  const factory OAuthAuthorizeParams({
    required String clientId,
    required String redirectUri,
    required String scope,
    required String responseType,
    String? state,
    String? codeChallenge,
    String? codeChallengeMethod,
    String? nonce,
  }) = _OAuthAuthorizeParams;

  const OAuthAuthorizeParams._();

  factory OAuthAuthorizeParams.fromUri(Uri uri) {
    final q = uri.queryParameters;
    return OAuthAuthorizeParams(
      clientId: q['client_id'] ?? '',
      redirectUri: q['redirect_uri'] ?? '',
      scope: q['scope'] ?? '',
      responseType: q['response_type'] ?? 'code',
      state: q['state'],
      codeChallenge: q['code_challenge'],
      codeChallengeMethod: q['code_challenge_method'],
      nonce: q['nonce'],
    );
  }

  Map<String, String> toQueryParameters() {
    final m = <String, String>{
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scope,
      'response_type': responseType,
    };
    if (state != null) m['state'] = state!;
    if (codeChallenge != null) m['code_challenge'] = codeChallenge!;
    if (codeChallengeMethod != null) m['code_challenge_method'] = codeChallengeMethod!;
    if (nonce != null) m['nonce'] = nonce!;
    return m;
  }
}
