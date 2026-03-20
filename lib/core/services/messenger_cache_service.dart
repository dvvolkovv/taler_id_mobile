import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-based cache for messenger conversations and messages.
/// Provides instant loading from local storage before server fetch.
class MessengerCacheService {
  static const _conversationsBox = 'messenger_conversations';
  static const _messagesBox = 'messenger_messages';
  static const _maxMessagesPerConversation = 100;

  static Future<void> init() async {
    try {
      await Future.wait([
        Hive.openBox(_conversationsBox),
        Hive.openBox(_messagesBox),
      ]);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_conversationsBox);
      await Hive.deleteBoxFromDisk(_messagesBox);
      await Future.wait([
        Hive.openBox(_conversationsBox),
        Hive.openBox(_messagesBox),
      ]);
    }
  }

  // ─── Conversations ───

  Future<void> saveConversations(List<Map<String, dynamic>> conversations) async {
    final box = Hive.box(_conversationsBox);
    await box.put('list', jsonEncode(conversations));
    await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  List<Map<String, dynamic>>? getConversations() {
    final box = Hive.box(_conversationsBox);
    final raw = box.get('list') as String?;
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  // ─── Messages ───

  Future<void> saveMessages(String conversationId, List<Map<String, dynamic>> messages) async {
    final box = Hive.box(_messagesBox);
    // Keep only the last N messages
    final toSave = messages.length > _maxMessagesPerConversation
        ? messages.sublist(messages.length - _maxMessagesPerConversation)
        : messages;
    await box.put(conversationId, jsonEncode(toSave));
  }

  List<Map<String, dynamic>>? getMessages(String conversationId) {
    final box = Hive.box(_messagesBox);
    final raw = box.get(conversationId) as String?;
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  /// Append a single message to the cache for a conversation.
  Future<void> appendMessage(String conversationId, Map<String, dynamic> message) async {
    final existing = getMessages(conversationId) ?? [];
    // Avoid duplicates
    existing.removeWhere((m) => m['id'] == message['id']);
    existing.add(message);
    await saveMessages(conversationId, existing);
  }

  /// Update a single message in cache (e.g. delivery/read status).
  Future<void> updateMessage(String conversationId, String messageId, Map<String, dynamic> updates) async {
    final messages = getMessages(conversationId);
    if (messages == null) return;
    for (int i = 0; i < messages.length; i++) {
      if (messages[i]['id'] == messageId) {
        messages[i] = {...messages[i], ...updates};
        break;
      }
    }
    await saveMessages(conversationId, messages);
  }

  /// Remove a message from cache.
  Future<void> removeMessage(String conversationId, String messageId) async {
    final messages = getMessages(conversationId);
    if (messages == null) return;
    messages.removeWhere((m) => m['id'] == messageId);
    await saveMessages(conversationId, messages);
  }

  Future<void> clearAll() async {
    try {
      await Hive.box(_conversationsBox).clear();
      await Hive.box(_messagesBox).clear();
    } catch (_) {}
  }
}
