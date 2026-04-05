import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists messages that were queued locally but haven't yet been confirmed
/// by the server. Messages stay in the queue until a server-assigned
/// message with the same content/conversation arrives (then they're removed),
/// or until the user manually retries.
///
/// The key format allows O(1) lookup by temp id.
class PendingMessageService {
  static const _boxName = 'pending_messages';
  Box? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
    }
  }

  /// Add or replace a pending message. The `message` map should contain at
  /// least `id`, `conversationId`, `content`, plus any optional file fields
  /// that need re-sending.
  Future<void> save(String tempId, Map<String, dynamic> message) async {
    if (_box == null) return;
    await _box!.put(tempId, jsonEncode(message));
  }

  Future<void> remove(String tempId) async {
    await _box?.delete(tempId);
  }

  /// Returns all pending messages across all conversations, sorted by the
  /// embedded temp id (which is `temp_<millisecondsSinceEpoch>`), so older
  /// messages are replayed first.
  List<Map<String, dynamic>> getAll() {
    if (_box == null) return [];
    final keys = _box!.keys.cast<String>().toList()..sort();
    final out = <Map<String, dynamic>>[];
    for (final k in keys) {
      final raw = _box!.get(k) as String?;
      if (raw == null) continue;
      try {
        final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        m['id'] = k; // ensure temp id is in the map
        out.add(m);
      } catch (_) {}
    }
    return out;
  }

  List<Map<String, dynamic>> getForConversation(String conversationId) {
    return getAll()
        .where((m) => m['conversationId'] == conversationId)
        .toList();
  }

  Future<void> clearAll() async {
    await _box?.clear();
  }
}
