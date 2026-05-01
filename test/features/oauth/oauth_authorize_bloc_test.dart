import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/grant_info.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/oauth_authorize_params.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/scope_descriptor.dart';
import 'package:taler_id_mobile/features/oauth/domain/repositories/oauth_repository.dart';
import 'package:taler_id_mobile/features/oauth/presentation/bloc/oauth_authorize_bloc.dart';
import 'package:taler_id_mobile/features/oauth/presentation/bloc/oauth_authorize_event.dart';
import 'package:taler_id_mobile/features/oauth/presentation/bloc/oauth_authorize_state.dart';

class _MockRepo extends Mock implements OAuthRepository {}

const _params = OAuthAuthorizeParams(
  clientId: 'mybook',
  redirectUri: 'https://example.com/cb',
  scope: 'profile email',
  responseType: 'code',
  state: 'xyz',
  codeChallenge: 'abc',
  codeChallengeMethod: 'S256',
);

const _grantInfoFresh = GrantInfo(
  clientName: 'MyBook',
  scopes: [ScopeDescriptor(key: 'profile', label: 'Профиль', description: '...')],
  remembered: false,
);

const _grantInfoRemembered = GrantInfo(
  clientName: 'MyBook',
  scopes: [ScopeDescriptor(key: 'profile', label: 'Профиль', description: '...')],
  remembered: true,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_params);
  });

  group('OAuthAuthorizeBloc', () {
    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'LoadGrantInfo (remembered=false) → Loading → ConsentRequired',
      build: () {
        final repo = _MockRepo();
        when(() => repo.getGrantInfo(any())).thenAnswer((_) async => _grantInfoFresh);
        return OAuthAuthorizeBloc(repo);
      },
      act: (bloc) => bloc.add(const LoadGrantInfo(_params)),
      expect: () => [
        const OAuthLoading(),
        const OAuthConsentRequired(_grantInfoFresh, _params),
      ],
    );

    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'LoadGrantInfo (remembered=true) → Loading → AutoApproving → Success',
      build: () {
        final repo = _MockRepo();
        when(() => repo.getGrantInfo(any())).thenAnswer((_) async => _grantInfoRemembered);
        when(() => repo.approve(any())).thenAnswer(
          (_) async => const OAuthApproveResult('https://example.com/cb?code=AUTO&state=xyz'),
        );
        return OAuthAuthorizeBloc(repo);
      },
      act: (bloc) => bloc.add(const LoadGrantInfo(_params)),
      expect: () => [
        const OAuthLoading(),
        const OAuthAutoApproving(),
        const OAuthSuccess('https://example.com/cb?code=AUTO&state=xyz'),
      ],
    );

    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'ApprovePressed from ConsentRequired → Approving → Success',
      build: () {
        final repo = _MockRepo();
        when(() => repo.approve(any())).thenAnswer(
          (_) async => const OAuthApproveResult('https://example.com/cb?code=USER&state=xyz'),
        );
        return OAuthAuthorizeBloc(repo);
      },
      seed: () => const OAuthConsentRequired(_grantInfoFresh, _params),
      act: (bloc) => bloc.add(const ApprovePressed()),
      expect: () => [
        const OAuthApproving(_grantInfoFresh, _params),
        const OAuthSuccess('https://example.com/cb?code=USER&state=xyz'),
      ],
    );

    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'CancelPressed from ConsentRequired → Cancelled with error redirect',
      build: () => OAuthAuthorizeBloc(_MockRepo()),
      seed: () => const OAuthConsentRequired(_grantInfoFresh, _params),
      act: (bloc) => bloc.add(const CancelPressed()),
      expect: () => [
        const OAuthCancelled(
          'https://example.com/cb?error=access_denied&state=xyz',
        ),
      ],
    );

    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'getGrantInfo error → Failure with retry hint',
      build: () {
        final repo = _MockRepo();
        when(() => repo.getGrantInfo(any())).thenThrow(Exception('network'));
        return OAuthAuthorizeBloc(repo);
      },
      act: (bloc) => bloc.add(const LoadGrantInfo(_params)),
      expect: () => [
        const OAuthLoading(),
        isA<OAuthFailure>(),
      ],
    );

    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'approve error → returns to ConsentRequired',
      build: () {
        final repo = _MockRepo();
        when(() => repo.approve(any())).thenThrow(Exception('500'));
        return OAuthAuthorizeBloc(repo);
      },
      seed: () => const OAuthConsentRequired(_grantInfoFresh, _params),
      act: (bloc) => bloc.add(const ApprovePressed()),
      expect: () => [
        const OAuthApproving(_grantInfoFresh, _params),
        const OAuthConsentRequired(_grantInfoFresh, _params),
      ],
    );
  });
}
