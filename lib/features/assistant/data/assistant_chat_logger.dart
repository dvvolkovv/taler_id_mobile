import 'dart:async';

/// Batch queue for POST /assistant/chat/log.
/// Network errors are swallowed (transcript replicas are best-effort);
/// a failed batch is re-queued once.
class AssistantChatLogger {
  AssistantChatLogger({
    required Future<void> Function(List<Map<String, dynamic>>) flush,
    this.debounce = const Duration(seconds: 3),
  }) : _flush = flush;

  final Future<void> Function(List<Map<String, dynamic>>) _flush;
  final Duration debounce;
  final List<Map<String, dynamic>> _queue = [];
  Timer? _timer;
  bool _requeued = false;

  void addUser(String text, {required String source, String? itemId}) => _add({
        'role': 'user',
        'source': source,
        'text': text,
        if (itemId != null) 'itemId': itemId,
      });

  void addAssistant(String text, {required String source, String? itemId}) =>
      _add({
        'role': 'assistant',
        'source': source,
        'text': text,
        if (itemId != null) 'itemId': itemId,
      });

  /// Removes queued (not yet flushed) entries tagged with [itemId].
  /// Used by the voice-gate: retracted foreign turns must not be persisted.
  void dropByItemId(String itemId) =>
      _queue.removeWhere((e) => e['itemId'] == itemId);

  void addAction({
    required String role,
    required String source,
    required String text,
    required Map<String, dynamic> action,
  }) =>
      _add({'role': role, 'source': source, 'text': text, 'action': action});

  void _add(Map<String, dynamic> entry) {
    _queue.add(entry);
    _timer?.cancel();
    _timer = Timer(debounce, () => flushNow());
  }

  Future<void> flushNow() async {
    _timer?.cancel();
    if (_queue.isEmpty) return;
    // Strip the local-only itemId tag: the backend DTO whitelists fields and
    // would reject unknown keys.
    final batch = [
      for (final e in _queue)
        {
          for (final entry in e.entries)
            if (entry.key != 'itemId') entry.key: entry.value,
        },
    ];
    _queue.clear();
    try {
      await _flush(batch);
      _requeued = false;
    } catch (_) {
      if (!_requeued) {
        _queue.insertAll(0, batch);
        _requeued = true;
      }
    }
  }

  void dispose() => _timer?.cancel();
}
