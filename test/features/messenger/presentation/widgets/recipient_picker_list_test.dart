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

  test('display name: the conversation name, else the other person', () {
    expect(recipientDisplayName(_team), 'Taler team');
    expect(recipientDisplayName(_anna), 'Anna Ivanova');
    expect(recipientDisplayName(_conv('c-x', 'DIRECT')), '');
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
}
