import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:taler_id_mobile/features/voice/presentation/controllers/room_chat_controller.dart';
import 'package:taler_id_mobile/features/voice/presentation/widgets/room_chat_panel.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('показывает сообщения из контроллера', (tester) async {
    final c = RoomChatController()
      ..handlePacket(
        {'type': 'chat_message', 'text': 'Привет', 'name': 'Аня'},
        fallbackName: 'Гость',
      );

    await tester.pumpWidget(_wrap(
      RoomChatPanel(controller: c, onSend: (_) {}, onRetry: (_) {}, onClose: () {}),
    ));

    expect(find.text('Привет'), findsOneWidget);
    expect(find.text('Аня'), findsOneWidget);
  });

  testWidgets('на пустой ленте показывает заглушку', (tester) async {
    await tester.pumpWidget(_wrap(
      RoomChatPanel(
        controller: RoomChatController(),
        onSend: (_) {},
        onRetry: (_) {},
        onClose: () {},
      ),
    ));

    expect(find.text('Пока никто ничего не написал'), findsOneWidget);
  });

  testWidgets('отдаёт введённый текст наружу и очищает поле', (tester) async {
    final sent = <String>[];

    await tester.pumpWidget(_wrap(
      RoomChatPanel(
        controller: RoomChatController(),
        onSend: sent.add,
        onRetry: (_) {},
        onClose: () {},
      ),
    ));

    await tester.enterText(find.byType(TextField), 'проверка');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(sent, ['проверка']);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
  });

  testWidgets('пустое сообщение наружу не уходит', (tester) async {
    final sent = <String>[];

    await tester.pumpWidget(_wrap(
      RoomChatPanel(
        controller: RoomChatController(),
        onSend: sent.add,
        onRetry: (_) {},
        onClose: () {},
      ),
    ));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(sent, isEmpty);
  });

  testWidgets('перерисовывается на новое сообщение', (tester) async {
    final c = RoomChatController();

    await tester.pumpWidget(_wrap(
      RoomChatPanel(controller: c, onSend: (_) {}, onRetry: (_) {}, onClose: () {}),
    ));
    expect(find.text('Привет'), findsNothing);

    c.handlePacket(
      {'type': 'chat_message', 'text': 'Привет', 'name': 'Аня'},
      fallbackName: 'Гость',
    );
    await tester.pump();

    expect(find.text('Привет'), findsOneWidget);
  });

  testWidgets('кнопка закрытия зовёт onClose', (tester) async {
    var closed = 0;

    await tester.pumpWidget(_wrap(
      RoomChatPanel(
        controller: RoomChatController(),
        onSend: (_) {},
        onRetry: (_) {},
        onClose: () => closed++,
      ),
    ));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(closed, 1);
  });

  // --- пометка «не отправлено» и повтор -------------------------------------

  testWidgets('неотправленное своё сообщение показывает пометку', (tester) async {
    final c = RoomChatController();
    c.addOwn('Я', 'привет', 'cid-1');
    c.markFailed('cid-1');

    await tester.pumpWidget(_wrap(
      RoomChatPanel(controller: c, onSend: (_) {}, onRetry: (_) {}, onClose: () {}),
    ));

    expect(find.text('Не отправлено'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('успешно отправленное своё сообщение пометку не показывает', (tester) async {
    final c = RoomChatController();
    c.addOwn('Я', 'привет', 'cid-2');

    await tester.pumpWidget(_wrap(
      RoomChatPanel(controller: c, onSend: (_) {}, onRetry: (_) {}, onClose: () {}),
    ));

    expect(find.text('Не отправлено'), findsNothing);
  });

  testWidgets('тап по пометке зовёт onRetry с этим же сообщением', (tester) async {
    final c = RoomChatController();
    c.addOwn('Я', 'привет', 'cid-3');
    c.markFailed('cid-3');
    final retried = <RoomChatMessage>[];

    await tester.pumpWidget(_wrap(
      RoomChatPanel(
        controller: c,
        onSend: (_) {},
        onRetry: retried.add,
        onClose: () {},
      ),
    ));

    await tester.tap(find.text('Не отправлено'));
    await tester.pump();

    expect(retried, hasLength(1));
    expect(retried.single.clientMsgId, 'cid-3');
    expect(retried.single.text, 'привет');
  });

  testWidgets('реконсилиация после сверки убирает пометку из UI', (tester) async {
    final c = RoomChatController();
    c.addOwn('Я', 'привет', 'cid-4');
    c.markFailed('cid-4');

    await tester.pumpWidget(_wrap(
      RoomChatPanel(controller: c, onSend: (_) {}, onRetry: (_) {}, onClose: () {}),
    ));
    expect(find.text('Не отправлено'), findsOneWidget);

    c.reconcile('cid-4', 'srv-4');
    await tester.pump();

    expect(find.text('Не отправлено'), findsNothing);
  });
}
