import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
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

  group('ColorTextInlineSyntax', () {
    List<md.Node> parse(String input) {
      final doc = md.Document(
        encodeHtml: false,
        inlineSyntaxes: [ColorTextInlineSyntax()],
      );
      return doc.parseInline(input);
    }

    md.Element firstColorText(List<md.Node> nodes) {
      return nodes.whereType<md.Element>().firstWhere(
        (e) => e.tag == 'color_text',
        orElse: () => throw StateError('no color_text element'),
      );
    }

    test('[HOT]x[/HOT] emits color_text with color=red', () {
      final el = firstColorText(parse('[HOT]wallet hot[/HOT]'));
      expect(el.tag, 'color_text');
      expect(el.attributes['color'], 'red');
      expect(el.textContent, 'wallet hot');
    });

    test('[COLD]x[/COLD] emits color_text with color=blue', () {
      final el = firstColorText(parse('[COLD]wallet cold[/COLD]'));
      expect(el.attributes['color'], 'blue');
      expect(el.textContent, 'wallet cold');
    });

    test('[C:red]/[C:blue]/[C:yellow]/[C:green] all emit canonical colors', () {
      for (final c in const ['red', 'blue', 'yellow', 'green']) {
        final el = firstColorText(parse('[C:$c]x[/C]'));
        expect(el.attributes['color'], c, reason: 'for color $c');
      }
    });

    test('mismatched closer [HOT]x[/COLD] does not match', () {
      final nodes = parse('[HOT]x[/COLD]');
      final elements = nodes.whereType<md.Element>().toList();
      expect(elements.where((e) => e.tag == 'color_text'), isEmpty);
    });

    test('unclosed [HOT]x does not match', () {
      final nodes = parse('[HOT]x');
      final elements = nodes.whereType<md.Element>().toList();
      expect(elements.where((e) => e.tag == 'color_text'), isEmpty);
    });

    test('unknown color [C:purple]x[/C] does not match', () {
      final nodes = parse('[C:purple]x[/C]');
      final elements = nodes.whereType<md.Element>().toList();
      expect(elements.where((e) => e.tag == 'color_text'), isEmpty);
    });

    test('two tags in one string yield two independent elements', () {
      final nodes = parse('[HOT]a[/HOT] and [COLD]b[/COLD]');
      final elements = nodes.whereType<md.Element>()
          .where((e) => e.tag == 'color_text').toList();
      expect(elements, hasLength(2));
      expect(elements[0].attributes['color'], 'red');
      expect(elements[0].textContent, 'a');
      expect(elements[1].attributes['color'], 'blue');
      expect(elements[1].textContent, 'b');
    });
  });
}
