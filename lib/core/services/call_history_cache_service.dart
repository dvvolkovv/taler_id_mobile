import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists the call history list and the user's personal room so the Calls
/// screen can render instantly from cache on open, then refresh in the
/// background. Raw JSON from the API is stored to avoid losing fields.
class CallHistoryCacheService {
  static const _boxName = 'call_history_cache';
  static const _kHistory = 'history';
  static const _kPersonalRoom = 'personal_room';
  Box? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
    }
  }

  // ── History ─────────────────────────────────────────

  Future<void> saveHistory(List<Map<String, dynamic>> entries) async {
    if (_box == null) return;
    await _box!.put(_kHistory, jsonEncode(entries));
  }

  List<Map<String, dynamic>>? getHistory() {
    if (_box == null) return null;
    final raw = _box!.get(_kHistory) as String?;
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  // ── Personal room ────────────────────────────────────

  Future<void> savePersonalRoom(Map<String, dynamic>? room) async {
    if (_box == null) return;
    if (room == null) {
      await _box!.delete(_kPersonalRoom);
    } else {
      await _box!.put(_kPersonalRoom, jsonEncode(room));
    }
  }

  Map<String, dynamic>? getPersonalRoom() {
    if (_box == null) return null;
    final raw = _box!.get(_kPersonalRoom) as String?;
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await _box?.clear();
  }
}
