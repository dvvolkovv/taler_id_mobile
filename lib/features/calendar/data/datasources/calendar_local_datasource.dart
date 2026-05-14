import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/calendar_event_entity.dart';

class CalendarLocalDataSource {
  static const String boxName = 'calendar_events_local';

  Box<String> get _box => Hive.box<String>(boxName);

  Future<List<CalendarEventEntity>> getAll() async {
    final list = _box.keys
        .cast<String>()
        .map((k) => _decode(_box.get(k)!))
        .whereType<CalendarEventEntity>()
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  Future<CalendarEventEntity?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _decode(raw);
  }

  Future<void> upsert(CalendarEventEntity event) async {
    await _box.put(event.id, jsonEncode(event.toJson()));
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  Stream<List<CalendarEventEntity>> watchAll() {
    final controller = StreamController<List<CalendarEventEntity>>.broadcast();
    StreamSubscription? sub;
    controller.onListen = () async {
      controller.add(await getAll());
      sub = _box.watch().listen((_) async {
        controller.add(await getAll());
      });
    };
    controller.onCancel = () async {
      await sub?.cancel();
    };
    return controller.stream;
  }

  CalendarEventEntity? _decode(String raw) {
    try {
      return CalendarEventEntity.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
