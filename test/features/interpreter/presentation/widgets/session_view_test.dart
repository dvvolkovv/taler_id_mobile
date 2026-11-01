import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_models.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/widgets/session_view.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/bloc/interpreter_state.dart' show InterpreterLinkState;
import 'package:taler_id_mobile/features/interpreter/room/caption_lines.dart';
import 'package:taler_id_mobile/features/interpreter/room/interpreter_signal.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

const _partner = InterpreterPartner(firstName: 'Alice', lang: 'en');
const _languages = [InterpreterLanguage(code: 'en', name: 'English')];

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

/// Like [_wrap], but pins the test surface to [width] logical pixels (via
/// `tester.view`, the only thing that actually narrows the layout — a
/// `SizedBox` nested under `MaterialApp.builder` can't shrink below the
/// ambient (tight) window constraint) and scales text by [textScale].
Future<void> _pumpAtWidth(
  WidgetTester tester,
  Widget child, {
  required double width,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, navigator) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: navigator!,
    ),
    home: Scaffold(body: child),
  ));
}

InterpreterSessionView _buildView({
  bool isHost = false,
  InterpreterEngine toMe = InterpreterEngine.simultaneous,
  bool partnerSpeaking = false,
  bool agentPresent = true,
  InterpreterLinkState connection = InterpreterLinkState.ok,
  bool micOn = true,
  String? spentPlanck,
  CaptionLines? captions,
  ValueChanged<bool>? onMicToggle,
  VoidCallback? onEnd,
  DateTime? now,
}) {
  final startedAt = DateTime(2026, 11, 1, 12, 0, 0);
  return InterpreterSessionView(
    isHost: isHost,
    partner: _partner,
    directions: InterpreterDirections(
        toMe: toMe, fromMe: InterpreterEngine.simultaneous),
    captions: captions ?? CaptionLines(),
    partnerSpeaking: partnerSpeaking,
    meSpeaking: false,
    agentPresent: agentPresent,
    connection: connection,
    micOn: micOn,
    startedAt: startedAt,
    spentPlanck: spentPlanck,
    languages: _languages,
    onMicToggle: onMicToggle ?? (_) {},
    onEnd: onEnd ?? () {},
    now: () => now ?? startedAt.add(const Duration(minutes: 1, seconds: 5)),
  );
}

void main() {
  testWidgets('shows partner name and language', (tester) async {
    await tester.pumpWidget(_wrap(_buildView()));
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('shows "partner is speaking" only while partnerSpeaking is true',
      (tester) async {
    await tester.pumpWidget(_wrap(_buildView(partnerSpeaking: true)));
    await tester.pump();
    expect(find.text('your partner is speaking…'), findsOneWidget);

    await tester.pumpWidget(_wrap(_buildView(partnerSpeaking: false)));
    await tester.pump();
    expect(find.text('your partner is speaking…'), findsNothing);
  });

  testWidgets('shows the phrase badge only when directions.toMe is phrase',
      (tester) async {
    await tester.pumpWidget(_wrap(_buildView(toMe: InterpreterEngine.phrase)));
    await tester.pump();
    expect(find.text('phrase-by-phrase translation'), findsOneWidget);

    await tester
        .pumpWidget(_wrap(_buildView(toMe: InterpreterEngine.simultaneous)));
    await tester.pump();
    expect(find.text('phrase-by-phrase translation'), findsNothing);
  });

  testWidgets('always shows the "runs through the server" note',
      (tester) async {
    await tester.pumpWidget(_wrap(_buildView()));
    await tester.pump();
    expect(find.text('Translation runs through the server'), findsOneWidget);
  });

  testWidgets(
      'host sees the elapsed timer and the spent amount; guest sees neither',
      (tester) async {
    await tester
        .pumpWidget(_wrap(_buildView(isHost: true, spentPlanck: '12000000')));
    await tester.pump();
    expect(find.text('1:05'), findsOneWidget);
    expect(find.text('Spent: 12 μTAL'), findsOneWidget);

    await tester
        .pumpWidget(_wrap(_buildView(isHost: false, spentPlanck: '12000000')));
    await tester.pump();
    expect(find.text('1:05'), findsNothing);
    expect(find.text('Spent: 12 μTAL'), findsNothing);
  });

  testWidgets('shows the agent-absent banner when the agent is not present',
      (tester) async {
    await tester.pumpWidget(_wrap(_buildView(agentPresent: false)));
    await tester.pump();
    expect(find.text('Translation stopped, waiting…'), findsOneWidget);
  });

  testWidgets('shows the reconnecting banner when the link is reconnecting',
      (tester) async {
    await tester.pumpWidget(
        _wrap(_buildView(connection: InterpreterLinkState.reconnecting)));
    await tester.pump();
    expect(find.text('Translation is reconnecting…'), findsOneWidget);
  });

  testWidgets('no trouble banner when the agent is present and the link is ok',
      (tester) async {
    await tester.pumpWidget(_wrap(_buildView()));
    await tester.pump();
    expect(find.text('Translation stopped, waiting…'), findsNothing);
    expect(find.text('Translation is reconnecting…'), findsNothing);
  });

  testWidgets(
      'shows its own distinct banner text when the link has failed, not the '
      'agent-absent text', (tester) async {
    await tester
        .pumpWidget(_wrap(_buildView(connection: InterpreterLinkState.failed)));
    await tester.pump();
    expect(find.text('Translation could not be restored'), findsOneWidget);
    expect(find.text('Translation stopped, waiting…'), findsNothing);
  });

  testWidgets(
      'the mic/end buttons share the row width at a large text scale on a '
      'narrow screen without overflowing', (tester) async {
    // The old fixed `SizedBox(width: 150)` pair left 320 - (150*2+16) = 4px
    // of margin on an iPhone-SE-class 320px-wide screen — razor-thin, and a
    // `RenderFlex overflowed` exception reproduces outright at 300px (e.g. a
    // notched device's safe-area insets eating into the usable width).
    // `Expanded` removes the fixed widths altogether, so this holds at any
    // width, not just one that happens to clear 316px by a few pixels.
    await _pumpAtWidth(tester, _buildView(), width: 300, textScale: 1.5);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'renders translation and own-speech caption lines, distinctly styled',
      (tester) async {
    final captions = CaptionLines()
      ..add(
          const CaptionSignal(
              role: CaptionRole.translation,
              speaker: 'u2',
              text: 'Hola',
              isFinal: true),
          DateTime(2026))
      ..add(
          const CaptionSignal(
              role: CaptionRole.source,
              speaker: 'u1',
              text: 'Hello',
              isFinal: true),
          DateTime(2026));

    await tester.pumpWidget(_wrap(_buildView(captions: captions)));
    await tester.pump();

    final translationFinder = find.text('Hola');
    final sourceFinder = find.text('Hello');
    expect(translationFinder, findsOneWidget);
    expect(sourceFinder, findsOneWidget);

    final translationStyle = tester.widget<Text>(translationFinder).style!;
    final sourceStyle = tester.widget<Text>(sourceFinder).style!;
    expect(translationStyle.fontSize, isNot(sourceStyle.fontSize));
  });

  testWidgets(
      'mic button toggles and fires onMicToggle with the opposite state',
      (tester) async {
    bool? toggledTo;
    await tester.pumpWidget(
        _wrap(_buildView(micOn: true, onMicToggle: (v) => toggledTo = v)));
    await tester.pump();

    await tester.tap(find.text('Microphone'));
    await tester.pump();

    expect(toggledTo, isFalse);
  });

  testWidgets('end button fires onEnd', (tester) async {
    var ended = false;
    await tester.pumpWidget(_wrap(_buildView(onEnd: () => ended = true)));
    await tester.pump();

    await tester.tap(find.text('End'));
    await tester.pump();

    expect(ended, isTrue);
  });
}
