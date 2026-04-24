import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/presentation/widgets/analyst_streaming_bubble.dart';

void main() {
  testWidgets('renders pending text and a blinking cursor', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AnalystStreamingBubble(text: 'Hello world')),
    ));
    expect(find.text('Hello world'), findsOneWidget);
    expect(find.byKey(const Key('analyst-streaming-cursor')), findsOneWidget);
  });

  testWidgets('re-renders when text grows', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AnalystStreamingBubble(text: 'Hello')),
    ));
    expect(find.text('Hello'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AnalystStreamingBubble(text: 'Hello, world')),
    ));
    expect(find.text('Hello, world'), findsOneWidget);
  });
}
