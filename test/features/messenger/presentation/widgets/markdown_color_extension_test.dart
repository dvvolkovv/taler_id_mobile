import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/messenger/presentation/widgets/markdown_color_extension.dart';

void main() {
  group('MarkdownColorPalette', () {
    Future<BuildContext> ctx(WidgetTester tester, {bool dark = true}) async {
      late BuildContext captured;
      await tester.pumpWidget(MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Builder(builder: (c) {
          captured = c;
          return const SizedBox.shrink();
        }),
      ));
      return captured;
    }

    testWidgets('textColor resolves canonical names in dark theme', (tester) async {
      final c = await ctx(tester);
      expect(MarkdownColorPalette.textColor(c, 'red'),    const Color(0xFFEF4444));
      expect(MarkdownColorPalette.textColor(c, 'blue'),   const Color(0xFF167EF2));
      expect(MarkdownColorPalette.textColor(c, 'yellow'), const Color(0xFFF59E0B));
      expect(MarkdownColorPalette.textColor(c, 'green'),  const Color(0xFF22C55E));
    });

    testWidgets('textColor resolves canonical names in light theme', (tester) async {
      final c = await ctx(tester, dark: false);
      expect(MarkdownColorPalette.textColor(c, 'red'),    const Color(0xFFDC2626));
      expect(MarkdownColorPalette.textColor(c, 'blue'),   const Color(0xFF1570D6));
      expect(MarkdownColorPalette.textColor(c, 'yellow'), const Color(0xFFD97706));
      expect(MarkdownColorPalette.textColor(c, 'green'),  const Color(0xFF16A34A));
    });

    testWidgets('textColor returns null for unknown names', (tester) async {
      final c = await ctx(tester);
      expect(MarkdownColorPalette.textColor(c, 'purple'), isNull);
      expect(MarkdownColorPalette.textColor(c, ''),       isNull);
    });

    testWidgets('badgeBackground uses 0.15 opacity of textColor', (tester) async {
      final c = await ctx(tester);
      final fg = MarkdownColorPalette.textColor(c, 'red')!;
      final bg = MarkdownColorPalette.badgeBackground(c, 'red')!;
      expect(bg, fg.withOpacity(0.15));
    });

    testWidgets('badgeBorder uses 0.35 opacity of textColor', (tester) async {
      final c = await ctx(tester);
      final fg = MarkdownColorPalette.textColor(c, 'red')!;
      final border = MarkdownColorPalette.badgeBorder(c, 'red')!;
      expect(border, fg.withOpacity(0.35));
    });

    testWidgets('badgeBackground/badgeBorder return null for unknown name', (tester) async {
      final c = await ctx(tester);
      expect(MarkdownColorPalette.badgeBackground(c, 'purple'), isNull);
      expect(MarkdownColorPalette.badgeBorder(c, 'purple'), isNull);
    });
  });
}
