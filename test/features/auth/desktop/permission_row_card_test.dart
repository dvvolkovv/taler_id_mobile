import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/auth/desktop/widgets/permission_row_card.dart';

Widget _harness(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 600, child: child))));

void main() {
  const accent = [Color(0xFF3B82F6), Color(0xFFA855F7)];

  testWidgets('not-handled state shows Разрешить button and no hint', (tester) async {
    await tester.pumpWidget(_harness(PermissionRowCard(
      icon: Icons.mic_none_outlined,
      title: 'Микрофон',
      description: 'desc',
      handled: false,
      granted: false,
      deniedHint: 'hint should not appear',
      accentGradient: accent,
      onPressed: () {},
    )));
    expect(find.text('Микрофон'), findsOneWidget);
    expect(find.text('Разрешить'), findsOneWidget);
    expect(find.text('Разрешено'), findsNothing);
    expect(find.text('Запрещено'), findsNothing);
    expect(find.text('hint should not appear'), findsNothing);
  });

  testWidgets('granted state shows ✓ Разрешено and no button, no hint',
      (tester) async {
    await tester.pumpWidget(_harness(PermissionRowCard(
      icon: Icons.mic_none_outlined,
      title: 'Микрофон',
      description: 'desc',
      handled: true,
      granted: true,
      deniedHint: 'hint should not appear',
      accentGradient: accent,
      onPressed: () {},
    )));
    expect(find.textContaining('Разрешено'), findsOneWidget);
    expect(find.text('Разрешить'), findsNothing);
    expect(find.textContaining('Запрещено'), findsNothing);
    expect(find.text('hint should not appear'), findsNothing);
  });

  testWidgets('denied state shows Запрещено and the deniedHint text',
      (tester) async {
    await tester.pumpWidget(_harness(PermissionRowCard(
      icon: Icons.mic_none_outlined,
      title: 'Микрофон',
      description: 'desc',
      handled: true,
      granted: false,
      deniedHint: '⚠ Включить в System Settings',
      accentGradient: accent,
      onPressed: () {},
    )));
    expect(find.textContaining('Запрещено'), findsOneWidget);
    expect(find.textContaining('Разрешено'), findsNothing);
    expect(find.text('Разрешить'), findsNothing);
    expect(find.text('⚠ Включить в System Settings'), findsOneWidget);
  });

  testWidgets('onPressed fires when tapping Разрешить', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_harness(PermissionRowCard(
      icon: Icons.mic_none_outlined,
      title: 'Микрофон',
      description: 'desc',
      handled: false,
      granted: false,
      deniedHint: 'never',
      accentGradient: accent,
      onPressed: () => tapped = true,
    )));
    await tester.tap(find.text('Разрешить'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
