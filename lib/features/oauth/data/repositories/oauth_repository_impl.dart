import '../../domain/entities/company_consent.dart';
import '../../domain/entities/grant_info.dart';
import '../../domain/entities/oauth_authorize_params.dart';
import '../../domain/repositories/oauth_repository.dart';
import '../datasources/oauth_remote_datasource.dart';

class OAuthRepositoryImpl implements OAuthRepository {
  final OAuthRemoteDatasource _remote;
  OAuthRepositoryImpl(this._remote);

  @override
  Future<GrantInfo> getGrantInfo(OAuthAuthorizeParams params) =>
      _remote.getGrantInfo(params);

  @override
  Future<OAuthApproveResult> approve(OAuthAuthorizeParams params, {CompanySelection? selection}) async {
    final redirectUri = await _remote.approve(params, selection: selection);
    return OAuthApproveResult(redirectUri);
  }
}
