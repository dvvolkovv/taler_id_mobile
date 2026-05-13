import 'package:hive_flutter/hive_flutter.dart';

class SyncCursorStorage {
  static const String boxName = 'messenger_sync';
  static const String _key = 'cursor';

  Future<String?> read() async {
    final box = Hive.box<String>(boxName);
    return box.get(_key);
  }

  Future<void> write(String cursor) async {
    final box = Hive.box<String>(boxName);
    await box.put(_key, cursor);
  }
}
