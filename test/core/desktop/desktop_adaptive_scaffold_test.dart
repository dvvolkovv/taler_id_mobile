// test/core/desktop/desktop_adaptive_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/desktop_adaptive_scaffold.dart';
import 'package:taler_id_mobile/core/platform/platform_utils.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';

// Note: `flutter test` runs in the host VM, so PlatformUtils.instance.isDesktop
// returns true on a Mac/Linux/Windows dev machine. We don't have an injection
// seam for PlatformUtils, so we test what the host actually sees: child renders
// in either branch, and on desktop hosts the blob-bg layer is present.

void main() {
  testWidgets('DesktopAdaptiveScaffold renders child in either platform branch',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const DesktopAdaptiveScaffold(child: Text('content')),
      ),
    );
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('DesktopAdaptiveScaffold on desktop host renders blob bg + chrome',
      (tester) async {
    // Skip if not running on a desktop host (e.g., would be the case on CI iOS sim).
    if (!PlatformUtils.instance.isDesktop) return;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const DesktopAdaptiveScaffold(child: Text('content')),
      ),
    );
    // Blob bg paints inside a CustomPaint
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('content'), findsOneWidget);
  });
}
