import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Generic Hive-backed list cache keyed by a box name. Used by Notes and
/// Calendar screens to render instantly and refresh in the background.
class SimpleListCache {
  final String boxName;
  Box? _box;

  SimpleListCache(this.boxName);

  Future<void> init() async {
    try {
      _box = await Hive.openBox(boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(boxName);
      _box = await Hive.openBox(boxName);
    }
  }

  Future<void> save(List<Map<String, dynamic>> items) async {
    if (_box == null) return;
    await _box!.put('items', jsonEncode(items));
  }

  List<Map<String, dynamic>>? get() {
    if (_box == null) return null;
    final raw = _box!.get('items') as String?;
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  /// Add or replace an item by its `id` field.
  Future<void> upsert(Map<String, dynamic> item) async {
    final items = get() ?? [];
    final id = item['id'];
    if (id != null) items.removeWhere((e) => e['id'] == id);
    items.insert(0, item);
    await save(items);
  }

  /// Remove an item by id.
  Future<void> remove(String id) async {
    final items = get();
    if (items == null) return;
    items.removeWhere((e) => e['id'] == id);
    await save(items);
  }

  Future<void> clear() async {
    await _box?.clear();
  }
}
