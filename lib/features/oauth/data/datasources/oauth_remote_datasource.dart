import '../../../../core/api/dio_client.dart';
import '../../domain/entities/grant_info.dart';
import '../../domain/entities/oauth_authorize_params.dart';

class OAuthRemoteDatasource {
  final DioClient client;
  OAuthRemoteDatasource(this.client);

  Future<GrantInfo> getGrantInfo(OAuthAuthorizeParams params) => client.get(
        '/oauth/mobile/grant-info',
        queryParameters: params.toQueryParameters(),
        fromJson: (d) => GrantInfo.fromJson(Map<String, dynamic>.from(d)),
      );

  Future<String> approve(OAuthAuthorizeParams params) => client.post(
        '/oauth/mobile/approve',
        data: params.toQueryParameters(),
        fromJson: (d) => Map<String, dynamic>.from(d)['redirect_uri'] as String,
      );
}
