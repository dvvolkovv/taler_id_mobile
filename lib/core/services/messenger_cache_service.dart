import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/messenger/domain/entities/conversation_entity.dart';

/// Hive-based cache for messenger conversations and messages.
/// Provides instant loading from local storage before server fetch.
class MessengerCacheService {
  static const _conversationsBox = 'messenger_conversations';
  static const _messagesBox = 'messenger_messages';
  static const _meshBoxName = 'mesh_messages';
  static const _maxMessagesPerConversation = 100;

  static Future<void> init() async {
    try {
      await Future.wait([
        Hive.openBox(_conversationsBox),
        Hive.openBox(_messagesBox),
        Hive.openBox<String>(_meshBoxName),
      ]);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_conversationsBox);
      await Hive.deleteBoxFromDisk(_messagesBox);
      await Hive.deleteBoxFromDisk(_meshBoxName);
      await Future.wait([
        Hive.openBox(_conversationsBox),
        Hive.openBox(_messagesBox),
        Hive.openBox<String>(_meshBoxName),
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

  /// Phase 1e — look up a cached conversation by id. Returns null when not
  /// cached — the resolver treats this as "mesh route unavailable".
  ConversationEntity? getConversationById(String id) {
    try {
      final raw = getConversations();
      if (raw == null) return null;
      for (final map in raw) {
        if (map['id'] == id) {
          return ConversationEntity.fromJson(map);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Phase 1f — find the existing DIRECT (1:1) conversation with a given
  /// contact userId. Returns null when no 1:1 conversation is cached; callers
  /// are expected to fall back to `meshOnly:<userId>` in that case.
  ConversationEntity? getConversationByContact(String contactUserId) {
    try {
      final raw = getConversations();
      if (raw == null) return null;
      for (final map in raw) {
        final type = map['type'] as String? ?? 'DIRECT';
        if (type != 'DIRECT') continue;
        if (map['otherUserId'] == contactUserId) {
          return ConversationEntity.fromJson(map);
        }
      }
    } catch (_) {}
    return null;
  }

  // ─── Mesh history ───

  /// Phase 1f — append a mesh-delivered message (either direction) to the
  /// per-conversation list. Idempotent: a second call with the same `id`
  /// under the same `conversationId` is a no-op.
  Future<void> appendMeshMessage(Map<String, dynamic> entry) async {
    final convId = entry['conversationId'] as String?;
    if (convId == null || convId.isEmpty) return;
    final Box<String> box;
    try {
      box = Hive.box<String>(_meshBoxName);
    } catch (_) {
      debugPrint('[mesh-cache] mesh_messages box not open, dropping entry');
      return;
    }
    final key = 'mesh_history_$convId';
    try {
      final raw = box.get(key);
      final list = raw != null
          ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      final newId = entry['id'] as String?;
      if (newId != null && list.any((m) => m['id'] == newId)) return;
      list.add(entry);
      await box.put(key, jsonEncode(list));
    } catch (e, st) {
      debugPrint('[mesh-cache] appendMeshMessage failed: $e\n$st');
    }
  }

  /// Phase 1f — read mesh history for a conversation, oldest-first by
  /// `sentAt`. Timestamps are parsed to `DateTime` so UTC-suffixed (`Z`) and
  /// naive ISO strings are compared on equal footing.
  List<Map<String, dynamic>> getMeshMessagesFor(String conversationId) {
    final Box<String> box;
    try {
      box = Hive.box<String>(_meshBoxName);
    } catch (_) {
      return const [];
    }
    final raw = box.get('mesh_history_$conversationId');
    if (raw == null) return const [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      list.sort((a, b) {
        final sa = DateTime.tryParse(a['sentAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final sb = DateTime.tryParse(b['sentAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return sa.compareTo(sb);
      });
      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<void> clearAll() async {
    try { await Hive.box(_conversationsBox).clear(); } catch (_) {}
    try { await Hive.box(_messagesBox).clear(); } catch (_) {}
    try { await Hive.box<String>(_meshBoxName).clear(); } catch (_) {}
  }
}
