import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/linkified_text.dart';

/// Виджет общий для чата, транскрипта ассистента и истории звонков. Если он
/// перестанет рисовать текст, пустой окажется каждая лента сразу — поэтому
/// проверяется именно то, что текст доезжает до экрана.
void main() {
  const style = TextStyle(fontSize: 14);

  Future<void> pump(WidgetTester t, Widget child) =>
      t.pumpWidget(MaterialApp(home: Scaffold(body: child)));

  /// Ищет строку и в обычном Text, и внутри собранных спанов.
  bool hasText(WidgetTester t, String needle) {
    for (final rt in t.widgetList<RichText>(find.byType(RichText))) {
      if (rt.text.toPlainText().contains(needle)) return true;
    }
    for (final p in t.widgetList<Text>(find.byType(Text))) {
      if ((p.data ?? '').contains(needle)) return true;
    }
    return false;
  }

  testWidgets('renders plain text', (t) async {
    await pump(t, const LinkifiedText(text: 'обычное сообщение', style: style));
    expect(hasText(t, 'обычное сообщение'), isTrue);
  });

  testWidgets('renders text containing a link', (t) async {
    await pump(t, const LinkifiedText(text: 'см. https://example.com тут', style: style));
    expect(hasText(t, 'example.com'), isTrue);
  });

  testWidgets('renders long multiline text', (t) async {
    final long = List.generate(40, (i) => 'строка $i').join('\n');
    await pump(t, LinkifiedText(text: long, style: style));
    expect(hasText(t, 'строка 0'), isTrue);
  });

  testWidgets('renders markup when richMarkup is on', (t) async {
    await pump(t, const LinkifiedText(
        text: 'это **важно** и ||секрет||', style: style, richMarkup: true));
    expect(hasText(t, 'важно'), isTrue);
    expect(hasText(t, 'секрет'), isTrue);
  });

  testWidgets('markers stay literal when richMarkup is off', (t) async {
    await pump(t, const LinkifiedText(text: 'это **важно**', style: style));
    expect(hasText(t, '**важно**'), isTrue);
  });

  testWidgets('renders release-notes style text with markers and a link', (t) async {
    // Ровно то, что лежит в системном канале: разметка, переносы и ссылка.
    const notes = '**Что нового в 1.1.25**\n\n'
        '- Закреплённые сообщения\n'
        '- Исправления\n\n'
        'Скачать: https://id.taler.tirol/download/taler-id-dev.apk';
    await pump(t, const LinkifiedText(text: notes, style: style, richMarkup: true));
    expect(hasText(t, 'Закреплённые сообщения'), isTrue);
    expect(hasText(t, 'Что нового'), isTrue);
  });

  testWidgets('a mention is rendered, not swallowed', (t) async {
    await pump(t, const LinkifiedText(
      text: 'привет @anna',
      style: style,
      mentionStyle: TextStyle(fontWeight: FontWeight.bold),
    ));
    expect(hasText(t, '@anna'), isTrue);
  });
}
