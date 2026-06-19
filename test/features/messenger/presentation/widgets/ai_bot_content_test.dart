import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/messenger/presentation/screens/chat_room_screen.dart';

void main() {
  testWidgets('AiBotContent renders mixed color tags + ACTION button', (tester) async {
    const content =
        'USDT-TRC20 [HOT_BADGE]HOT[/HOT_BADGE] `TX...` — [HOT]12 450.50[/HOT]\n\n'
        '[ACTION:📋 Все ожидающие]';

    // No BlocProvider needed: AiBotContent.build does not read any bloc.
    // context.read<MessengerBloc>() lives only inside _ActionCardButton.onTap,
    // and this test never taps. If a future change moves the read into build,
    // this test will fail loudly and we add a BlocProvider then.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: AiBotContent(
            content: content,
            conversationId: 'conv-test',
            topicId: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Action button shows the human-readable label.
    expect(find.textContaining('Все ожидающие'), findsOneWidget);

    // Coloured HOT text exists somewhere in the rendered tree.
    final hotText = tester.widgetList<Text>(find.text('12 450.50'))
        .where((w) => w.style?.color == const Color(0xFFEF4444));
    expect(hotText, isNotEmpty, reason: 'HOT inline text should be red');

    // Badge container with radius 6 and red bg exists.
    final badge = tester.widgetList<Container>(find.byType(Container))
        .where((c) {
          if (c.decoration is! BoxDecoration) return false;
          final d = c.decoration as BoxDecoration;
          return d.borderRadius == BorderRadius.circular(6) &&
                 d.color == const Color(0xFFEF4444).withOpacity(0.15);
        });
    expect(badge, isNotEmpty, reason: 'HOT_BADGE should render a red pill container');
  });
}
