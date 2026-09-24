/// `call_answered` events that could not go out because the socket was not
/// connected yet — typically a call accepted from the lock screen, where
/// CallKit hands us the accept before the app has brought the socket up.
///
/// The socket's own send buffer is not enough: `connect()` disposes the old
/// socket and builds a new one on login, dropping whatever was buffered. This
/// queue lives on the datasource instead and is drained on every `connect`.
class PendingCallAnswers {
  /// Past this, the call is long over — announcing an answer would only make
  /// the caller's UI treat a stale echo as "answered on another device".
  static const ttl = Duration(seconds: 60);

  PendingCallAnswers({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final _pending = <String, ({String conversationId, DateTime queuedAt})>{};

  void add(String conversationId, String roomName) {
    _pending.putIfAbsent(
      roomName,
      () => (conversationId: conversationId, queuedAt: _clock()),
    );
  }

  /// The call ended before the socket came up — nothing left to announce.
  void remove(String roomName) => _pending.remove(roomName);

  /// Everything still fresh, in the order it was queued. Empties the queue so
  /// a later reconnect does not repeat the event.
  List<({String conversationId, String roomName})> drain() {
    final now = _clock();
    final fresh = [
      for (final e in _pending.entries)
        if (now.difference(e.value.queuedAt) < ttl)
          (conversationId: e.value.conversationId, roomName: e.key),
    ];
    _pending.clear();
    return fresh;
  }
}
