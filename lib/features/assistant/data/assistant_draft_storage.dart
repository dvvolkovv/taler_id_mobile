import 'package:hive/hive.dart';

class AssistantDraftStorage {
  AssistantDraftStorage(this._box);
  final Box<String> _box;
  static const _key = 'draft';

  String? read() {
    final v = _box.get(_key);
    return (v == null || v.isEmpty) ? null : v;
  }

  void save(String text) {
    if (text.isEmpty) {
      _box.delete(_key);
    } else {
      _box.put(_key, text);
    }
  }

  void clear() => _box.delete(_key);
}
