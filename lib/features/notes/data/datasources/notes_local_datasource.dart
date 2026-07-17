import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/note_entity.dart';

class NotesLocalDataSource {
  static const String boxName = 'notes_local';
  static const String tombstoneBoxName = 'notes_tombstones';
  static const Duration tombstoneTtl = Duration(hours: 24);

  Box<String> get _box => Hive.box<String>(boxName);
  Box<String> get _tombstones => Hive.box<String>(tombstoneBoxName);

  /// Remember that [id] was deleted locally. `refresh()` must never upsert a
  /// tombstoned id back, even after its DELETE outbox op has drained — the
  /// server list can lag behind the delete (stale cache/replica) and would
  /// otherwise resurrect the note (user report 2026-07-17: "не с первого
  /// раза удаляются заметки").
  Future<void> markTombstone(String id) async {
    await _tombstones.put(id, DateTime.now().toUtc().toIso8601String());
  }

  /// Live tombstones; expired ones (older than [tombstoneTtl]) are GC'd on
  /// read. After the TTL the server copy wins again — if the DELETE never
  /// reached the server, the note legitimately comes back.
  Future<Set<String>> tombstonedIds() async {
    final now = DateTime.now().toUtc();
    final out = <String>{};
    for (final k in _tombstones.keys.cast<String>().toList()) {
      final ts = DateTime.tryParse(_tombstones.get(k) ?? '');
      if (ts == null || now.difference(ts) > tombstoneTtl) {
        await _tombstones.delete(k);
        continue;
      }
      out.add(k);
    }
    return out;
  }

  Future<List<NoteEntity>> getAll() async {
    final list = _box.keys
        .cast<String>()
        .map((k) => _decode(_box.get(k)!))
        .whereType<NoteEntity>()
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<NoteEntity?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _decode(raw);
  }

  Future<void> upsert(NoteEntity note) async {
    await _box.put(note.id, jsonEncode(note.toJson()));
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  Stream<List<NoteEntity>> watchAll() {
    late StreamController<List<NoteEntity>> controller;
    StreamSubscription<BoxEvent>? boxSub;

    Future<void> emit() async {
      if (!controller.isClosed) {
        controller.add(await getAll());
      }
    }

    controller = StreamController<List<NoteEntity>>(
      onListen: () async {
        await emit();
        boxSub = _box.watch().listen((_) => emit());
      },
      onCancel: () {
        boxSub?.cancel();
        controller.close();
      },
    );
    return controller.stream;
  }

  NoteEntity? _decode(String raw) {
    try {
      return NoteEntity.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}
