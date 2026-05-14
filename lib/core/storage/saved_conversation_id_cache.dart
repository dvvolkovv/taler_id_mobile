import 'package:hive_flutter/hive_flutter.dart';

/// Persists the current user's SAVED-conversation id locally so the pinned
/// `SavedPinnedTile` can open the chat instantly (and offline) on subsequent
/// taps after the first online open.
///
/// Mirrors the shape of [SyncCursorStorage]: tiny Hive box with a single key.
class SavedConversationIdCache {
  static const String boxName = 'saved_conv_id';
  static const String _key = 'id';

  Future<String?> read() async {
    try {
      final box = Hive.box<String>(boxName);
      return box.get(_key);
    } catch (_) {
      // Defensive: corrupted box / not opened. Treat as cache miss.
      return null;
    }
  }

  Future<void> write(String id) async {
    final box = Hive.box<String>(boxName);
    await box.put(_key, id);
  }

  Future<void> clear() async {
    final box = Hive.box<String>(boxName);
    await box.delete(_key);
  }
}
