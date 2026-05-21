// test/core/desktop/focus_ring_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/focus_ring.dart';

void main() {
  testWidgets('FocusRing wraps child without focus', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FocusRing(child: SizedBox(width: 50, height: 50))),
    );
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
