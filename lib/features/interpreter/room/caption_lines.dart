import 'interpreter_signal.dart';

/// One subtitle line. Delta lines (simultaneous engine) stay `isFinal: false`
/// while more text keeps arriving for them; phrase lines (phrase engine)
/// are always `isFinal: true` and never grow.
class CaptionLine {
  final String text;
  final CaptionRole role;
  final bool isFinal;

  const CaptionLine({
    required this.text,
    required this.role,
    required this.isFinal,
  });
}

/// Pure assembly of caption subtitles from the agent's `caption` signals,
/// kept separately per [CaptionRole] since `source` (own speech) and
/// `translation` (partner's speech) run independently and can overlap.
///
/// Time is injected rather than read from the wall clock so the gap rule is
/// deterministic in tests.
class CaptionLines {
  static const _gap = Duration(milliseconds: 1200);
  static const _maxPerRole = 20;

  final Map<CaptionRole, List<CaptionLine>> _lines = {
    for (final role in CaptionRole.values) role: <CaptionLine>[],
  };
  final Map<CaptionRole, DateTime> _lastDeltaAt = {};

  /// Newest last, at most the last 20 lines for [role].
  List<CaptionLine> linesFor(CaptionRole role) =>
      List.unmodifiable(_lines[role]!);

  void add(CaptionSignal signal, DateTime now) {
    final role = signal.role;
    final list = _lines[role]!;

    if (signal.isFinal) {
      // The phrase engine hands over a whole utterance at once; it never
      // merges with whatever delta line happened to be open for this role.
      list.add(CaptionLine(text: signal.text, role: role, isFinal: true));
      _lastDeltaAt.remove(role);
      _trim(list);
      return;
    }

    final last = _lastDeltaAt[role];
    final gapped = last == null || now.difference(last) > _gap || list.isEmpty;
    if (gapped) {
      list.add(CaptionLine(text: signal.text, role: role, isFinal: false));
    } else {
      // Still inside the 1.2s window since the last delta of this role —
      // append to the open line rather than starting a new one.
      list[list.length - 1] = CaptionLine(
        text: list.last.text + signal.text,
        role: role,
        isFinal: false,
      );
    }
    _lastDeltaAt[role] = now;
    _trim(list);
  }

  void _trim(List<CaptionLine> list) {
    while (list.length > _maxPerRole) {
      list.removeAt(0);
    }
  }
}
