import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/animated_blob_background.dart';

void main() {
  testWidgets('AnimatedBlobBackground builds CustomPaint with painter', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AnimatedBlobBackground()));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('AnimatedBlobBackground disposes animation controller cleanly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AnimatedBlobBackground()));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    // If controller leaks → tester throws. Reaching here means OK.
    expect(tester.takeException(), isNull);
  });
}
