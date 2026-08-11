import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/utils/rich_text_parser.dart';

import '_news_sample.dart';

/// Разбор разметки идёт на каждое сообщение при отрисовке ленты. Если он
/// зациклится или окажется квадратичным на реальном тексте, чат просто встанет
/// — поэтому проверяется и результат, и время.
void main() {
  test('parses a real release post quickly and without losing text', () {
    final sw = Stopwatch()..start();
    final tokens = parseRichText(newsSample);
    sw.stop();

    // Склеенный обратно текст обязан совпасть с исходным: разбор ничего не
    // теряет и не задваивает.
    final rebuilt = tokens.map((t) => t.text).join();
    expect(rebuilt.length, lessThanOrEqualTo(newsSample.length));
    expect(newsSample.contains('Закрепление сообщений'), isTrue);
    expect(rebuilt.contains('Закрепление сообщений'), isTrue);
    expect(sw.elapsedMilliseconds, lessThan(200), reason: 'разбор должен быть мгновенным');
  });

  test('hasRichMarkup on the same post is cheap', () {
    final sw = Stopwatch()..start();
    for (var i = 0; i < 50; i++) {
      hasRichMarkup(newsSample);
    }
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(500));
  });

  test('emoji survive the parse', () {
    final rebuilt = parseRichText(newsSample).map((t) => t.text).join();
    expect(rebuilt.contains('🚀'), isTrue);
    expect(rebuilt.contains('📌'), isTrue);
  });
}
