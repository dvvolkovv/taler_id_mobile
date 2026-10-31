import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/presentation/widgets/recipient_picker_list.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

ConversationEntity _conv(String id, String type,
        {String? name, String? otherUserName, String? myRole}) =>
    ConversationEntity(
      id: id,
      participantIds: const [],
      type: type,
      name: name,
      otherUserName: otherUserName,
      myRole: myRole,
    );

final _anna = _conv('c-anna', 'DIRECT', otherUserName: 'Anna Ivanova');
final _team = _conv('c-team', 'GROUP', name: 'Taler team');
final _news =
    _conv('c-news', 'CHANNEL', name: 'Taler news', myRole: 'SUBSCRIBER');
final _saved = _conv('c-saved', 'SAVED', name: 'Saved conversation');

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  test('candidates: chats the user can write to, without Saved', () {
    expect(
      recipientCandidates([_anna, _team, _news, _saved]).map((c) => c.id),
      ['c-anna', 'c-team'],
    );
  });

  test('display name: the conversation name, else the other person; '
      'the AI analyst by its app title', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(recipientDisplayName(_team, en), 'Taler team');
    expect(recipientDisplayName(_anna, en), 'Anna Ivanova');
    expect(recipientDisplayName(_conv('c-x', 'DIRECT'), en), '');
    expect(
        recipientDisplayName(
            _conv('c-ai', 'AI_ANALYST', name: 'AI Аналитик'), en),
        'AI Analyst');
  });

  testWidgets('shows writable chats and Favorites once, at the top',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _team, _news, _saved],
      onSelected: (_) {},
      onSelectSaved: () {},
    )));
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Anna Ivanova'), findsOneWidget);
    expect(find.text('Taler team'), findsOneWidget);
    expect(find.text('Taler news'), findsNothing);
    expect(find.text('Saved conversation'), findsNothing);
    expect(tester.getTopLeft(find.text('Favorites')).dy,
        lessThan(tester.getTopLeft(find.text('Anna Ivanova')).dy));
  });

  testWidgets('search narrows by the shown name and hides Favorites',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _team],
      onSelected: (_) {},
      onSelectSaved: () {},
    )));
    await tester.enterText(find.byType(TextField), 'ANNA');
    await tester.pump();
    expect(find.text('Anna Ivanova'), findsOneWidget);
    expect(find.text('Taler team'), findsNothing);
    expect(find.text('Favorites'), findsNothing);
    expect(find.text('No chats'), findsNothing);
  });

  testWidgets('tapping a chat reports that conversation', (tester) async {
    ConversationEntity? picked;
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _team],
      onSelected: (c) => picked = c,
    )));
    await tester.tap(find.text('Taler team'));
    await tester.pump();
    expect(picked?.id, 'c-team');
  });

  testWidgets('tapping Favorites calls onSelectSaved', (tester) async {
    var savedTaps = 0;
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna],
      onSelected: (_) {},
      onSelectSaved: () => savedTaps++,
    )));
    await tester.tap(find.text('Favorites'));
    await tester.pump();
    expect(savedTaps, 1);
  });

  testWidgets('no Favorites row without onSelectSaved', (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna],
      onSelected: (_) {},
    )));
    expect(find.text('Favorites'), findsNothing);
  });

  testWidgets('loading with nothing to show: a spinner, not "No chats"',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: const [],
      loading: true,
      onSelected: (_) {},
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No chats'), findsNothing);
  });

  testWidgets('loaded and empty: "No chats"', (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: const [],
      onSelected: (_) {},
    )));
    expect(find.text('No chats'), findsOneWidget);
  });

  testWidgets('Favorites stays on top of the spinner while chats load',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: const [],
      loading: true,
      onSelected: (_) {},
      onSelectSaved: () {},
    )));
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No chats'), findsNothing);
  });

  testWidgets('a search with no matches shows an empty list', (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _team],
      onSelected: (_) {},
      onSelectSaved: () {},
    )));
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('No chats'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('typing while chats still load keeps the spinner',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: const [],
      loading: true,
      onSelected: (_) {},
    )));
    await tester.enterText(find.byType(TextField), 'anna');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('an unnamed conversation is shown as "Dialog"', (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_conv('c-x', 'DIRECT')],
      onSelected: (_) {},
    )));
    expect(find.text('Dialog'), findsOneWidget);
  });

  testWidgets('the AI analyst is listed and found by its app title',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _conv('c-ai', 'AI_ANALYST', name: 'AI Аналитик')],
      onSelected: (_) {},
    )));
    expect(find.text('AI Analyst'), findsOneWidget);
    expect(find.text('AI Аналитик'), findsNothing);
    await tester.enterText(find.byType(TextField), 'analyst');
    await tester.pump();
    expect(find.text('AI Analyst'), findsOneWidget);
    expect(find.text('Anna Ivanova'), findsNothing);
  });

  testWidgets('spaces around the query are ignored', (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _team],
      onSelected: (_) {},
      onSelectSaved: () {},
    )));
    await tester.enterText(find.byType(TextField), ' anna ');
    await tester.pump();
    expect(find.text('Anna Ivanova'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Taler team'), findsOneWidget);
  });
}
