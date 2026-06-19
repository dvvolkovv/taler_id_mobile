import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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

  group('ColorBadgeInlineSyntax', () {
    List<md.Node> parse(String input) {
      final doc = md.Document(
        encodeHtml: false,
        inlineSyntaxes: [ColorBadgeInlineSyntax()],
      );
      return doc.parseInline(input);
    }

    md.Element firstBadge(List<md.Node> nodes) {
      return nodes.whereType<md.Element>().firstWhere(
        (e) => e.tag == 'color_badge',
        orElse: () => throw StateError('no color_badge element'),
      );
    }

    test('[HOT_BADGE]x[/HOT_BADGE] emits color_badge red', () {
      final el = firstBadge(parse('[HOT_BADGE]HOT[/HOT_BADGE]'));
      expect(el.attributes['color'], 'red');
      expect(el.textContent, 'HOT');
    });

    test('[COLD_BADGE]x[/COLD_BADGE] emits color_badge blue', () {
      final el = firstBadge(parse('[COLD_BADGE]COLD[/COLD_BADGE]'));
      expect(el.attributes['color'], 'blue');
      expect(el.textContent, 'COLD');
    });

    test('[B:red]/[B:blue]/[B:yellow]/[B:green] emit canonical badges', () {
      for (final c in const ['red', 'blue', 'yellow', 'green']) {
        final el = firstBadge(parse('[B:$c]LBL[/B]'));
        expect(el.attributes['color'], c, reason: 'for color $c');
      }
    });

    test('mismatched [HOT_BADGE]x[/COLD_BADGE] does not match', () {
      final nodes = parse('[HOT_BADGE]x[/COLD_BADGE]');
      expect(nodes.whereType<md.Element>().where((e) => e.tag == 'color_badge'), isEmpty);
    });

    test('unclosed [HOT_BADGE]x does not match', () {
      final nodes = parse('[HOT_BADGE]x');
      expect(nodes.whereType<md.Element>().where((e) => e.tag == 'color_badge'), isEmpty);
    });

    test('unknown badge color [B:purple]x[/B] does not match', () {
      final nodes = parse('[B:purple]x[/B]');
      expect(nodes.whereType<md.Element>().where((e) => e.tag == 'color_badge'), isEmpty);
    });
  });

  group('ColorTextBuilder', () {
    Widget renderMarkdown(String data, {bool dark = true}) {
      return MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => MarkdownBody(
              data: data,
              extensionSet: md.ExtensionSet(
                md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                [ColorTextInlineSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
              ),
              builders: {'color_text': ColorTextBuilder(ctx)},
            ),
          ),
        ),
      );
    }

    Text findColoredText(WidgetTester tester, String content, Color expected) {
      return tester.widgetList<Text>(find.text(content))
          .firstWhere((w) => w.style?.color == expected,
              orElse: () => throw StateError(
                'no Text with content="$content" and color=$expected — '
                'found ${tester.widgetList<Text>(find.text(content)).map((w) => w.style?.color).toList()}'));
    }

    testWidgets('[HOT]x[/HOT] renders text in dark-theme red', (tester) async {
      await tester.pumpWidget(renderMarkdown('[HOT]hot wallet[/HOT]'));
      await tester.pumpAndSettle();
      final text = findColoredText(tester, 'hot wallet', const Color(0xFFEF4444));
      expect(text.style?.color, const Color(0xFFEF4444));
    });

    testWidgets('[COLD]x[/COLD] renders text in light-theme blue', (tester) async {
      await tester.pumpWidget(renderMarkdown('[COLD]cold wallet[/COLD]', dark: false));
      await tester.pumpAndSettle();
      final text = findColoredText(tester, 'cold wallet', const Color(0xFF1570D6));
      expect(text.style?.color, const Color(0xFF1570D6));
    });

    testWidgets('all four [C:name] colors render correctly in dark theme', (tester) async {
      const expected = {
        'red':    Color(0xFFEF4444),
        'blue':   Color(0xFF167EF2),
        'yellow': Color(0xFFF59E0B),
        'green':  Color(0xFF22C55E),
      };
      for (final entry in expected.entries) {
        await tester.pumpWidget(renderMarkdown('[C:${entry.key}]label[/C]'));
        await tester.pumpAndSettle();
        final text = findColoredText(tester, 'label', entry.value);
        expect(text.style?.color, entry.value, reason: 'for color ${entry.key}');
      }
    });
  });
}
