import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/company_consent.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/grant_info.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/oauth_authorize_params.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/scope_descriptor.dart';
import 'package:taler_id_mobile/features/oauth/presentation/bloc/oauth_authorize_bloc.dart';
import 'package:taler_id_mobile/features/oauth/presentation/bloc/oauth_authorize_event.dart';
import 'package:taler_id_mobile/features/oauth/presentation/bloc/oauth_authorize_state.dart';
import 'package:taler_id_mobile/features/oauth/presentation/screens/oauth_authorize_screen.dart';

class _MockBloc extends MockBloc<OAuthAuthorizeEvent, OAuthAuthorizeState>
    implements OAuthAuthorizeBloc {}

const _params = OAuthAuthorizeParams(
  clientId: 'mybook',
  redirectUri: 'https://example.com/cb',
  scope: 'profile',
  responseType: 'code',
);

const _grantInfo = GrantInfo(
  clientName: 'MyBook',
  scopes: [
    ScopeDescriptor(key: 'profile', label: 'Профиль', description: 'Имя, фамилия'),
  ],
  remembered: false,
);

const _companies = CompanyConsent(
  personName: 'Иван Петров',
  eligible: [CompanyOption(id: 'a', name: 'Ромашка', legalName: 'ООО «Ромашка»', role: 'OWNER')],
  unverified: [UnverifiedCompany(id: 'c', name: 'Василёк')],
);
const _grantInfoCompanies = GrantInfo(
  clientName: 'Trientes', scopes: [], remembered: false, companies: _companies,
);

Widget _harness(OAuthAuthorizeBloc bloc) => MaterialApp(
      home: BlocProvider<OAuthAuthorizeBloc>.value(
        value: bloc,
        child: OAuthAuthorizeScreen(params: _params, onLaunchUrl: (_) async {}),
      ),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const LoadGrantInfo(_params));
  });

  testWidgets('ConsentRequired renders client name, scope list, buttons',
      (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const OAuthConsentRequired(_grantInfo, _params));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_harness(bloc));
    await tester.pumpAndSettle();

    expect(find.textContaining('MyBook'), findsWidgets);
    expect(find.textContaining('Профиль'), findsOneWidget);
    expect(find.textContaining('Имя, фамилия'), findsOneWidget);
    expect(find.text('Разрешить'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
  });

  testWidgets('Tap Разрешить dispatches ApprovePressed', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const OAuthConsentRequired(_grantInfo, _params));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_harness(bloc));
    await tester.tap(find.text('Разрешить'));
    await tester.pump();

    verify(() => bloc.add(const ApprovePressed())).called(1);
  });

  testWidgets('Tap Отмена dispatches CancelPressed', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const OAuthConsentRequired(_grantInfo, _params));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_harness(bloc));
    await tester.tap(find.text('Отмена'));
    await tester.pump();

    verify(() => bloc.add(const CancelPressed())).called(1);
  });

  testWidgets('Loading state shows spinner', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const OAuthLoading());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_harness(bloc));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Success state triggers onLaunchUrl with redirect', (tester) async {
    final bloc = _MockBloc();
    String? launched;
    whenListen<OAuthAuthorizeState>(
      bloc,
      Stream.fromIterable([
        const OAuthSuccess('https://example.com/cb?code=ABC&state=xyz'),
      ]),
      initialState: const OAuthLoading(),
    );

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<OAuthAuthorizeBloc>.value(
        value: bloc,
        child: OAuthAuthorizeScreen(
          params: _params,
          onLaunchUrl: (url) async {
            launched = url;
          },
        ),
      ),
    ));
    // pump enough frames for the BlocConsumer listener to fire without
    // calling pumpAndSettle (which loops forever on the spinner animation).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(launched, 'https://example.com/cb?code=ABC&state=xyz');
  });

  testWidgets('companies: act-as choices, share list, unverified hint', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const OAuthConsentRequired(_grantInfoCompanies, _params,
        selection: CompanySelection(actAs: 'a', companyIds: ['a'])));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_harness(bloc));
    await tester.pumpAndSettle();

    expect(find.text('Войти как'), findsOneWidget);
    expect(find.text('Иван Петров'), findsOneWidget);
    expect(find.text('ООО «Ромашка»'), findsNWidgets(2)); // «войти как» и «передать»
    expect(find.text('Передать данные компаний'), findsOneWidget);
    expect(find.textContaining('Василёк'), findsOneWidget);
    // компания из «войти как» отмечена и заблокирована
    final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(box.value, isTrue);
    expect(box.onChanged, isNull);
  });

  testWidgets('tapping a person option dispatches ActAsChanged', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const OAuthConsentRequired(_grantInfoCompanies, _params,
        selection: CompanySelection(actAs: 'a', companyIds: ['a'])));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_harness(bloc));
    await tester.tap(find.text('Иван Петров'));
    await tester.pump();

    verify(() => bloc.add(const ActAsChanged('person'))).called(1);
  });

  testWidgets('approving: choices are disabled, buttons stay on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const OAuthApproving(_grantInfoCompanies, _params,
        selection: CompanySelection(actAs: 'person', companyIds: ['a'])));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_harness(bloc));
    await tester.pump();

    expect(find.text('Отмена').hitTestable(), findsOneWidget);
    final radios =
        tester.widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>));
    expect(radios, hasLength(2));
    for (final tile in radios) {
      expect(tile.enabled, isFalse);
    }
    final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(box.value, isTrue);
    expect(box.onChanged, isNull);

    await tester.tap(find.text('ООО «Ромашка»').first, warnIfMissed: false);
    await tester.pump();
    verifyNever(() => bloc.add(any(that: isA<ActAsChanged>())));
  });

  testWidgets('failure screen has no broken "open in browser" link', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const OAuthFailure('boom', _params));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_harness(bloc));
    await tester.pumpAndSettle();

    expect(find.textContaining('boom'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Открыть в браузере'), findsNothing);
  });
}
