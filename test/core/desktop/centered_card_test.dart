import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/centered_card.dart';

void main() {
  testWidgets('CenteredCard wraps child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CenteredCard(child: Text('inner'))),
    );
    expect(find.text('inner'), findsOneWidget);
  });

  testWidgets('CenteredCard applies default padding', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CenteredCard(child: SizedBox.shrink())),
    );
    final padding = tester.widget<Padding>(
      find.descendant(of: find.byType(CenteredCard), matching: find.byType(Padding)).last,
    );
    expect((padding.padding as EdgeInsets).top, 32.0);
  });
}
