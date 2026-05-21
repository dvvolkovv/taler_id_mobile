// test/core/desktop/hover_lift_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/hover_lift.dart';

void main() {
  testWidgets('HoverLift renders child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HoverLift(child: Text('btn'))),
    );
    expect(find.text('btn'), findsOneWidget);
  });
}
