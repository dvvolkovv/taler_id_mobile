import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/features/oauth/data/datasources/oauth_remote_datasource.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/company_consent.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/oauth_authorize_params.dart';

class _MockDioClient extends Mock implements DioClient {}

const _params = OAuthAuthorizeParams(
  clientId: 'trientes',
  redirectUri: 'https://trientes.org/cb',
  scope: 'openid companies',
  responseType: 'code',
  state: 'xyz',
  codeChallenge: 'abc',
  codeChallengeMethod: 'S256',
);

void main() {
  late _MockDioClient http;
  late OAuthRemoteDatasource ds;

  setUp(() {
    http = _MockDioClient();
    ds = OAuthRemoteDatasource(http);
    when(() => http.post<String>(any(),
        data: any(named: 'data'), fromJson: any(named: 'fromJson'))).thenAnswer((inv) async {
      final fromJson = inv.namedArguments[#fromJson] as String Function(dynamic);
      return fromJson({'redirect_uri': 'https://trientes.org/cb?code=x'});
    });
  });

  Map<dynamic, dynamic> sentBody() => verify(() => http.post<String>('/oauth/mobile/approve',
          data: captureAny(named: 'data'), fromJson: any(named: 'fromJson')))
      .captured
      .single as Map;

  group('OAuthRemoteDatasource.approve', () {
    test('without a choice the body is exactly the authorize params', () async {
      expect(await ds.approve(_params), 'https://trientes.org/cb?code=x');

      final body = sentBody();
      expect(body, _params.toQueryParameters());
      expect(body.containsKey('act_as'), isFalse);
      expect(body.containsKey('company_ids'), isFalse);
    });

    test('with a choice the body adds act_as and company_ids', () async {
      await ds.approve(_params,
          selection: const CompanySelection(actAs: 'a', companyIds: ['a', 'b']));

      expect(sentBody(), {
        ..._params.toQueryParameters(),
        'act_as': 'a',
        'company_ids': ['a', 'b'],
      });
    });
  });
}
