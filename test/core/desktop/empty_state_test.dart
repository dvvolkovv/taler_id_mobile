// test/core/desktop/empty_state_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/empty_state.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';

void main() {
  testWidgets('EmptyState renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const EmptyState(
          icon: Icons.call_outlined,
          title: 'Нет звонков',
          subtitle: 'Позвоните контакту',
        ),
      ),
    );
    expect(find.text('Нет звонков'), findsOneWidget);
    expect(find.text('Позвоните контакту'), findsOneWidget);
    expect(find.byIcon(Icons.call_outlined), findsOneWidget);
  });

  testWidgets('EmptyState renders action button when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: EmptyState(
          icon: Icons.add,
          title: 'Empty',
          action: FilledButton(onPressed: () {}, child: const Text('Add')),
        ),
      ),
    );
    expect(find.text('Add'), findsOneWidget);
  });
}
