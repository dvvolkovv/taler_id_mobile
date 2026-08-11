/// Разметка сообщений: **жирный**, __курсив__, ~~зачёркнутый~~, `код` и
/// ||спойлер||.
///
/// Разметка живёт прямо в тексте, а не отдельной моделью отступов. Так она
/// переживает пересылку и цитирование, а клиент, который её не понимает,
/// покажет сами символы — это некрасиво, но читаемо, в отличие от потерянного
/// форматирования.
library;

enum RichStyle { plain, bold, italic, strike, code, spoiler }

class RichToken {
  final String text;
  final RichStyle style;
  const RichToken(this.text, this.style);

  @override
  bool operator ==(Object other) =>
      other is RichToken && other.text == text && other.style == style;
  @override
  int get hashCode => Object.hash(text, style);

  @override
  String toString() => 'RichToken(${style.name}, "$text")';
}

/// Пары маркеров. Порядок важен: `**` проверяется раньше `*`-подобных, иначе
/// жирный разобрался бы как два пустых курсива.
const _markers = <String, RichStyle>{
  '||': RichStyle.spoiler,
  '**': RichStyle.bold,
  '__': RichStyle.italic,
  '~~': RichStyle.strike,
  '`': RichStyle.code,
};

/// Разбирает текст на куски со стилями.
///
/// Незакрытый маркер остаётся обычным текстом: человек, набравший «2**2», не
/// должен видеть, как половина сообщения вдруг стала жирной.
///
/// Вложенность не поддерживается намеренно — внутри `код` и ||спойлера||
/// разметка не разбирается, там текст показывается как есть.
List<RichToken> parseRichText(String input) {
  if (input.isEmpty) return const [];
  final out = <RichToken>[];
  final buf = StringBuffer();

  void flushPlain() {
    if (buf.isNotEmpty) {
      out.add(RichToken(buf.toString(), RichStyle.plain));
      buf.clear();
    }
  }

  var i = 0;
  while (i < input.length) {
    String? hit;
    for (final m in _markers.keys) {
      if (input.startsWith(m, i)) {
        hit = m;
        break;
      }
    }
    if (hit == null) {
      buf.write(input[i]);
      i++;
      continue;
    }

    final closeAt = input.indexOf(hit, i + hit.length);
    // Незакрытый маркер или пустая пара (`****`) — это просто символы.
    if (closeAt == -1 || closeAt == i + hit.length) {
      buf.write(input[i]);
      i++;
      continue;
    }

    flushPlain();
    out.add(RichToken(input.substring(i + hit.length, closeAt), _markers[hit]!));
    i = closeAt + hit.length;
  }

  flushPlain();
  return out;
}

/// Есть ли в тексте хоть какая-то разметка.
///
/// Нужно, чтобы не гонять обычные сообщения через сборку стилей: их
/// подавляющее большинство.
bool hasRichMarkup(String input) =>
    parseRichText(input).any((t) => t.style != RichStyle.plain);

/// Оборачивает выделенный кусок маркерами — для кнопок форматирования.
///
/// Возвращает новый текст и то, где должен оказаться курсор: без этого он
/// прыгал бы в конец, и продолжать набор было бы невозможно.
({String text, int selectionStart, int selectionEnd}) applyMarker(
  String text,
  int start,
  int end,
  RichStyle style,
) {
  final marker = _markers.entries.firstWhere((e) => e.value == style).key;
  final safeStart = start.clamp(0, text.length);
  final safeEnd = end.clamp(safeStart, text.length);
  final selected = text.substring(safeStart, safeEnd);
  final wrapped = '$marker$selected$marker';
  return (
    text: text.replaceRange(safeStart, safeEnd, wrapped),
    selectionStart: safeStart + marker.length,
    selectionEnd: safeStart + marker.length + selected.length,
  );
}
