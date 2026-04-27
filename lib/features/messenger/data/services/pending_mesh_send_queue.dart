/// Retry queue for text messages that had no eligible mesh peers at first
/// send. Lives only in memory and persists for the app's lifetime —
/// entries are removed only via [remove] or process death. Late mesh
/// delivery is harmless because [MessengerBloc] dedupes by `clientId`
/// without a time bound.
///
/// See `docs/superpowers/specs/2026-04-27-mesh-phase2-2-pending-mesh-retry-design.md`.
class PendingMeshSendQueue {
  final Map<String, _Entry> _entries = {};

  PendingMeshSendQueue();

  /// Add or overwrite an entry for [clientId].
  void enqueue({
    required String clientId,
    required String conversationId,
    required String content,
    required DateTime sentAt,
  }) {
    _entries[clientId] = _Entry(
      clientId: clientId,
      conversationId: conversationId,
      content: content,
      sentAt: sentAt,
    );
  }

  /// Mark [peerUserId] as having received the message identified by
  /// [clientId]. Returns `true` if this is the first peer to be marked
  /// for that clientId (the entry's fanout-set was empty before this
  /// call). Returns `false` if the entry no longer exists or the
  /// fanout-set was non-empty.
  bool markFannedOut({required String clientId, required String peerUserId}) {
    final entry = _entries[clientId];
    if (entry == null) return false;
    final wasEmpty = entry.fannedOutTo.isEmpty;
    entry.fannedOutTo.add(peerUserId);
    return wasEmpty;
  }

  /// Entries whose conversation participants include [peerUserId] and that
  /// have not yet been fanned out to that peer.
  Iterable<PendingMeshSendEntry> dueFor({
    required String peerUserId,
    required Iterable<String> Function(String conversationId) participantsOf,
  }) sync* {
    for (final entry in _entries.values) {
      final participants = participantsOf(entry.conversationId);
      if (!participants.contains(peerUserId)) continue;
      if (entry.fannedOutTo.contains(peerUserId)) continue;
      yield PendingMeshSendEntry(
        clientId: entry.clientId,
        conversationId: entry.conversationId,
        content: entry.content,
        sentAt: entry.sentAt,
      );
    }
  }

  /// Explicitly remove the entry for [clientId]. No-op if not present.
  void remove(String clientId) {
    _entries.remove(clientId);
  }

  /// Number of entries currently in the queue.
  int get pendingCount => _entries.length;
}

class PendingMeshSendEntry {
  final String clientId;
  final String conversationId;
  final String content;
  final DateTime sentAt;
  PendingMeshSendEntry({
    required this.clientId,
    required this.conversationId,
    required this.content,
    required this.sentAt,
  });
}

class _Entry {
  final String clientId;
  final String conversationId;
  final String content;
  final DateTime sentAt;
  final Set<String> fannedOutTo = <String>{};

  _Entry({
    required this.clientId,
    required this.conversationId,
    required this.content,
    required this.sentAt,
  });
}
