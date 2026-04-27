import 'package:clock/clock.dart';

/// Retry queue for text messages that had no eligible mesh peers at first
/// send. Lives only in memory; entries expire 30 s after `sentAt`.
///
/// See `docs/superpowers/specs/2026-04-27-mesh-phase2-2-pending-mesh-retry-design.md`.
class PendingMeshSendQueue {
  final Duration ttl;
  final Map<String, _Entry> _entries = {};

  PendingMeshSendQueue({this.ttl = const Duration(seconds: 30)});

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
      expiresAt: sentAt.add(ttl),
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

  /// Entries currently within TTL whose conversation participants include
  /// [peerUserId] and that have not yet been fanned out to that peer.
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
  final DateTime expiresAt;
  final Set<String> fannedOutTo = <String>{};

  _Entry({
    required this.clientId,
    required this.conversationId,
    required this.content,
    required this.sentAt,
    required this.expiresAt,
  });
}

// ignore: unused_element
final _clockRef = clock; // keeps the clock import alive for Tasks 3+
