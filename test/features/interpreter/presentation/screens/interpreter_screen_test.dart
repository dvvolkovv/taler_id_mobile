import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_models.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/bloc/interpreter_bloc.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/bloc/interpreter_event.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/bloc/interpreter_state.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/screens/interpreter_screen.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

class _MockInterpreterBloc extends MockBloc<InterpreterEvent, InterpreterState>
    implements InterpreterBloc {}

const _catalog = InterpreterCatalog(
  enabled: true,
  languages: [InterpreterLanguage(code: 'ru', name: 'Русский')],
);

/// f1: a `talerid://interp/<code>` link must actually lead to joining — this
/// pumps the real screen (not just StartView in isolation) the way
/// `app_router.dart` builds it for that link, with the bloc it obtains from
/// GetIt (`sl<InterpreterBloc>(param1: ...)`, registered here the same way
/// `service_locator.dart` does it: `registerFactoryParam`) mocked out.
void main() {
  late _MockInterpreterBloc bloc;

  setUp(() {
    bloc = _MockInterpreterBloc();
    sl.registerFactoryParam<InterpreterBloc, String, void>((_, __) => bloc);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      );

  testWidgets(
      'a pending joinCode reaches a Choosing screen with a "Join" button '
      'that fires JoinPressed with that code', (tester) async {
    const state = InterpreterChoosing(
      catalog: _catalog,
      myLang: 'ru',
      joinCode: 'ABCD2345',
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<InterpreterState>.empty(),
        initialState: state);

    await tester
        .pumpWidget(wrap(const InterpreterScreen(joinCode: 'ABCD2345')));
    await tester.pumpAndSettle();

    expect(find.text('Join'), findsOneWidget);
    expect(find.text('Start'), findsNothing);

    await tester.tap(find.text('Join'));
    await tester.pump();

    verify(() => bloc.add(const JoinPressed('ABCD2345'))).called(1);
  });
}
