import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/presentation/widgets/pinned_banner.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

/// Minimal pinned-message fixture. [pinnedAt] doubles as [sentAt] — the
/// widget only reads `content`/`id` from the entity, but a full pin always
/// carries a non-null `pinnedAt` in real data.
MessageEntity _pin(String id, String content, DateTime pinnedAt) => MessageEntity(
      id: id,
      conversationId: 'conv-1',
      senderId: 'user-1',
      content: content,
      sentAt: pinnedAt,
      pinnedAt: pinnedAt,
      pinnedById: 'user-1',
    );

// getPinnedMessages() (and therefore PinnedBanner's `pins` contract) returns
// newest-pin-first — index 0 is always what the bar should show first.
// IDs are intentionally NOT in newest-to-oldest numeric order: several tests
// below assert on these literal id strings, so existing ones (_newest,
// _older) keep their original ids and _oldest — added later, for the
// index-shrink regression test — just gets a third, non-colliding one.
final _newest = _pin('msg-2', 'Newest pin text', DateTime(2026, 8, 8, 12));
final _older = _pin('msg-1', 'Older pin text', DateTime(2026, 8, 7, 12));
final _oldest = _pin('msg-0', 'Oldest pin text', DateTime(2026, 8, 6, 12));

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

void main() {
  testWidgets('with two pins shows the newest pin\'s text and "1 of 2"',
      (tester) async {
    await tester.pumpWidget(_wrap(PinnedBanner(
      pins: [_newest, _older],
      onJump: (_) {},
      onDismiss: () {},
      onOpenList: () {},
    )));

    expect(find.text('Newest pin text'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);
  });

  testWidgets(
      'tapping the body calls onJump with the currently shown pin id, then advances',
      (tester) async {
    final jumped = <String>[];
    await tester.pumpWidget(_wrap(PinnedBanner(
      pins: [_newest, _older],
      onJump: jumped.add,
      onDismiss: () {},
      onOpenList: () {},
    )));

    await tester.tap(find.text('Newest pin text'));
    await tester.pump();

    expect(jumped, ['msg-2']);
    expect(find.text('Older pin text'), findsOneWidget);
    expect(find.text('2 of 2'), findsOneWidget);
  });

  testWidgets('cycling past the last pin wraps back to the first',
      (tester) async {
    final jumped = <String>[];
    await tester.pumpWidget(_wrap(PinnedBanner(
      pins: [_newest, _older],
      onJump: jumped.add,
      onDismiss: () {},
      onOpenList: () {},
    )));

    await tester.tap(find.text('Newest pin text')); // 1 of 2 -> 2 of 2
    await tester.pump();
    await tester.tap(find.text('Older pin text')); // 2 of 2 -> wraps to 1 of 2
    await tester.pump();

    expect(jumped, ['msg-2', 'msg-1']);
    expect(find.text('Newest pin text'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);
  });

  testWidgets('tapping the close icon calls onDismiss', (tester) async {
    var dismissed = false;
    final jumped = <String>[];
    await tester.pumpWidget(_wrap(PinnedBanner(
      pins: [_newest, _older],
      onJump: jumped.add,
      onDismiss: () => dismissed = true,
      onOpenList: () {},
    )));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(dismissed, isTrue);
    // Closing must not also register as a body tap.
    expect(jumped, isEmpty);
  });

  testWidgets('with an empty list the widget renders nothing', (tester) async {
    await tester.pumpWidget(_wrap(const PinnedBanner(
      pins: [],
      onJump: _noopJump,
      onDismiss: _noop,
      onOpenList: _noop,
    )));

    expect(find.byType(PinnedBanner), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PinnedBanner),
        matching:
            find.byWidgetPredicate((w) => w is SizedBox && w.width == 0.0 && w.height == 0.0),
      ),
      findsOneWidget,
      reason: 'empty pins should render exactly SizedBox.shrink()',
    );
    expect(find.descendant(of: find.byType(PinnedBanner), matching: find.byType(Icon)),
        findsNothing);
    expect(find.descendant(of: find.byType(PinnedBanner), matching: find.byType(Text)),
        findsNothing);
  });

  testWidgets(
      'with exactly one pin, no counter is shown — says "Pinned message" instead',
      (tester) async {
    await tester.pumpWidget(_wrap(PinnedBanner(
      pins: [_newest],
      onJump: (_) {},
      onDismiss: () {},
      onOpenList: () {},
    )));

    expect(find.text('Pinned message'), findsOneWidget);
    expect(find.text('1 of 1'), findsNothing);
  });

  testWidgets('tapping the list icon calls onOpenList', (tester) async {
    var opened = false;
    final jumped = <String>[];
    await tester.pumpWidget(_wrap(PinnedBanner(
      pins: [_newest, _older],
      onJump: jumped.add,
      onDismiss: () {},
      onOpenList: () => opened = true,
    )));

    await tester.tap(find.byIcon(Icons.list_alt_rounded));
    await tester.pump();

    expect(opened, isTrue);
    // Opening the list must not also register as a body tap or a dismiss.
    expect(jumped, isEmpty);
  });

  testWidgets(
      'guards the index when the pins list shrinks — shows the remaining pin instead of throwing',
      (tester) async {
    await tester.pumpWidget(_wrap(PinnedBanner(
      pins: [_newest, _older, _oldest],
      onJump: (_) {},
      onDismiss: () {},
      onOpenList: () {},
    )));

    await tester.tap(find.text('Newest pin text')); // index 0 -> 1
    await tester.pump();
    await tester.tap(find.text('Older pin text')); // index 1 -> 2
    await tester.pump();
    expect(find.text('Oldest pin text'), findsOneWidget);
    expect(find.text('3 of 3'), findsOneWidget);

    // The list shrinks out from under the currently-shown index (2) down to
    // a single pin — same PinnedBanner element/state, new (shorter) `pins`.
    await tester.pumpWidget(_wrap(PinnedBanner(
      pins: [_newest],
      onJump: (_) {},
      onDismiss: () {},
      onOpenList: () {},
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Newest pin text'), findsOneWidget);
    expect(find.text('Pinned message'), findsOneWidget);
  });
}

void _noop() {}
void _noopJump(String _) {}
