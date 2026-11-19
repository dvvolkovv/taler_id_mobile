import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/company_consent.dart';
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

const _companies = CompanyConsent(
  personName: 'Иван',
  eligible: [
    CompanyOption(id: 'a', name: 'Ромашка', legalName: 'ООО «Ромашка»', role: 'OWNER'),
    CompanyOption(id: 'b', name: 'Лютик', role: 'ADMIN'),
  ],
  unverified: [],
  lastSelection: CompanySelection(actAs: 'a', companyIds: ['a']),
);

const _grantInfoCompanies = GrantInfo(
  clientName: 'Trientes',
  scopes: [ScopeDescriptor(key: 'companies', label: 'Компании', description: '...')],
  remembered: false,
  companies: _companies,
);

// Сайт просит `companies`, но подходящих компаний нет — блоки скрыты.
const _grantInfoNoEligible = GrantInfo(
  clientName: 'Trientes',
  scopes: [ScopeDescriptor(key: 'companies', label: 'Компании', description: '...')],
  remembered: false,
  companies: CompanyConsent(
    personName: 'Иван',
    eligible: [],
    unverified: [UnverifiedCompany(id: 'c', name: 'Василёк')],
  ),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_params);
    registerFallbackValue(const CompanySelection(actAs: 'person', companyIds: []));
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
        when(() => repo.approve(any(), selection: any(named: 'selection'))).thenAnswer(
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
        when(() => repo.approve(any(), selection: any(named: 'selection'))).thenAnswer(
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
        when(() => repo.approve(any(), selection: any(named: 'selection')))
            .thenThrow(Exception('500'));
        return OAuthAuthorizeBloc(repo);
      },
      seed: () => const OAuthConsentRequired(_grantInfoFresh, _params),
      act: (bloc) => bloc.add(const ApprovePressed()),
      expect: () => [
        const OAuthApproving(_grantInfoFresh, _params),
        const OAuthConsentRequired(_grantInfoFresh, _params),
      ],
    );

    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'with companies the selection starts from the last choice',
      build: () {
        final repo = _MockRepo();
        when(() => repo.getGrantInfo(any())).thenAnswer((_) async => _grantInfoCompanies);
        return OAuthAuthorizeBloc(repo);
      },
      act: (bloc) => bloc.add(const LoadGrantInfo(_params)),
      expect: () => [
        const OAuthLoading(),
        const OAuthConsentRequired(_grantInfoCompanies, _params,
            selection: CompanySelection(actAs: 'a', companyIds: ['a'])),
      ],
    );

    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'ActAsChanged switches who signs in and shares that company',
      build: () => OAuthAuthorizeBloc(_MockRepo()),
      seed: () => const OAuthConsentRequired(_grantInfoCompanies, _params,
          selection: CompanySelection(actAs: 'person', companyIds: [])),
      act: (bloc) => bloc.add(const ActAsChanged('b')),
      expect: () => [
        const OAuthConsentRequired(_grantInfoCompanies, _params,
            selection: CompanySelection(actAs: 'b', companyIds: ['b'])),
      ],
    );

    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'ShareToggled adds and removes a company, the act-as one stays shared',
      build: () => OAuthAuthorizeBloc(_MockRepo()),
      seed: () => const OAuthConsentRequired(_grantInfoCompanies, _params,
          selection: CompanySelection(actAs: 'a', companyIds: ['a'])),
      act: (bloc) => bloc
        ..add(const ShareToggled('b', true))
        ..add(const ShareToggled('b', false))
        ..add(const ShareToggled('a', false)),
      expect: () => [
        const OAuthConsentRequired(_grantInfoCompanies, _params,
            selection: CompanySelection(actAs: 'a', companyIds: ['a', 'b'])),
        const OAuthConsentRequired(_grantInfoCompanies, _params,
            selection: CompanySelection(actAs: 'a', companyIds: ['a'])),
      ],
    );

    late _MockRepo noEligibleRepo;
    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'companies without an eligible one: no choice in state, approve sends none',
      build: () {
        noEligibleRepo = _MockRepo();
        when(() => noEligibleRepo.getGrantInfo(any()))
            .thenAnswer((_) async => _grantInfoNoEligible);
        when(() => noEligibleRepo.approve(any(), selection: any(named: 'selection')))
            .thenAnswer((_) async => const OAuthApproveResult('https://trientes.org/cb?code=p'));
        return OAuthAuthorizeBloc(noEligibleRepo);
      },
      act: (bloc) async {
        bloc.add(const LoadGrantInfo(_params));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ApprovePressed());
      },
      expect: () => [
        const OAuthLoading(),
        const OAuthConsentRequired(_grantInfoNoEligible, _params),
        const OAuthApproving(_grantInfoNoEligible, _params),
        const OAuthSuccess('https://trientes.org/cb?code=p'),
      ],
      verify: (_) =>
          verify(() => noEligibleRepo.approve(_params, selection: null)).called(1),
    );

    late _MockRepo approveRepo;
    blocTest<OAuthAuthorizeBloc, OAuthAuthorizeState>(
      'Approve sends the selection',
      build: () {
        approveRepo = _MockRepo();
        when(() => approveRepo.approve(any(), selection: any(named: 'selection')))
            .thenAnswer((_) async => const OAuthApproveResult('https://trientes.org/cb?code=x'));
        return OAuthAuthorizeBloc(approveRepo);
      },
      seed: () => const OAuthConsentRequired(_grantInfoCompanies, _params,
          selection: CompanySelection(actAs: 'b', companyIds: ['b'])),
      act: (bloc) => bloc.add(const ApprovePressed()),
      expect: () => [
        const OAuthApproving(_grantInfoCompanies, _params,
            selection: CompanySelection(actAs: 'b', companyIds: ['b'])),
        const OAuthSuccess('https://trientes.org/cb?code=x'),
      ],
      verify: (_) => verify(() => approveRepo.approve(_params,
          selection: const CompanySelection(actAs: 'b', companyIds: ['b']))).called(1),
    );
  });
}
