import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  testWidgets('Failure state shows retry + browser fallback buttons', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const OAuthFailure('Network error', _params));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_harness(bloc));
    await tester.pumpAndSettle();

    expect(find.textContaining('Network error'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Открыть в браузере'), findsOneWidget);
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
}
