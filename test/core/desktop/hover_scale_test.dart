// test/core/desktop/hover_scale_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/hover_scale.dart';

void main() {
  testWidgets('HoverScale renders child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HoverScale(child: Icon(Icons.star))),
    );
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
