import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/presentation/bloc/assistant_chat_bloc.dart';
import 'package:taler_id_mobile/features/assistant/presentation/widgets/assistant_chat_feed.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

MessageEntity _msg(String id, String content, {bool assistant = false}) {
  return MessageEntity(
    id: id,
    conversationId: 'conv-1',
    senderId: 'user-1',
    content: content,
    sentAt: DateTime(2026, 7, 17, 12, 0),
    metadata: assistant ? {'assistantRole': 'assistant'} : null,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders messages and pending replica with opacity',
      (tester) async {
    await tester.pumpWidget(_wrap(AssistantChatFeed(
      messages: [
        _msg('m1', 'Привет, ассистент'),
        _msg('m2', 'Здравствуйте! Чем помочь?', assistant: true),
      ],
      status: AssistantChatStatus.ready,
      pending: const [
        PendingReplica(role: 'user', text: 'живая реплика', itemId: 'it-1'),
      ],
      onActionTap: (_) async {},
      onRetry: () {},
    )));

    expect(find.text('Привет, ассистент'), findsOneWidget);
    expect(find.textContaining('Здравствуйте! Чем помочь?'), findsOneWidget);
    expect(find.text('живая реплика'), findsOneWidget);
    // Pending replica is rendered semi-transparent.
    expect(
      find.ancestor(
        of: find.text('живая реплика'),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
  });

  testWidgets('error state with empty messages shows retry and fires onRetry',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(_wrap(AssistantChatFeed(
      messages: const [],
      status: AssistantChatStatus.error,
      error: 'boom',
      onActionTap: (_) async {},
      onRetry: () => retried = true,
    )));

    final retryButton = find.byType(OutlinedButton);
    expect(retryButton, findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(retryButton);
    expect(retried, isTrue);
  });
}
