import 'package:hive_flutter/hive_flutter.dart';

/// Persists unsent message drafts per conversation so that a user returning
/// to a chat (on the same or a different session) sees their in-progress text.
class MessageDraftService {
  static const _boxName = 'message_drafts';
  Box? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
    }
  }

  String? getDraft(String conversationId) {
    final v = _box?.get(conversationId) as String?;
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> saveDraft(String conversationId, String text) async {
    if (_box == null) return;
    if (text.trim().isEmpty) {
      await _box!.delete(conversationId);
    } else {
      await _box!.put(conversationId, text);
    }
  }

  Future<void> clearDraft(String conversationId) async {
    await _box?.delete(conversationId);
  }

  Future<void> clearAll() async {
    await _box?.clear();
  }
}
