import '../entities/grant_info.dart';
import '../entities/oauth_authorize_params.dart';

class OAuthApproveResult {
  final String redirectUri;
  const OAuthApproveResult(this.redirectUri);
}

abstract class OAuthRepository {
  Future<GrantInfo> getGrantInfo(OAuthAuthorizeParams params);
  Future<OAuthApproveResult> approve(OAuthAuthorizeParams params);
}
