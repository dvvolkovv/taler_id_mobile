import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/note_entity.dart';

class NotesLocalDataSource {
  static const String boxName = 'notes_local';

  Box<String> get _box => Hive.box<String>(boxName);

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
