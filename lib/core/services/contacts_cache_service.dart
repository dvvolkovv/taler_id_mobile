import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists the merged contacts list (accepted + pending) so the Contacts
/// screen can render instantly from cache and refresh in the background.
class ContactsCacheService {
  static const _boxName = 'contacts_cache';
  static const _key = 'items';
  Box? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
    }
  }

  Future<void> save(List<Map<String, dynamic>> items) async {
    if (_box == null) return;
    await _box!.put(_key, jsonEncode(items));
  }

  List<Map<String, dynamic>>? get() {
    if (_box == null) return null;
    final raw = _box!.get(_key) as String?;
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await _box?.clear();
  }
}
