import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/contact_item_entity.dart';

class ContactsLocalDataSource {
  static const String boxName = 'contacts_local';

  Box<String> get _box => Hive.box<String>(boxName);

  Future<List<ContactItemEntity>> getAll() async {
    final list = _box.keys
        .cast<String>()
        .map((k) => _decode(_box.get(k)!))
        .whereType<ContactItemEntity>()
        .toList();
    list.sort((a, b) {
      const order = {
        ContactStatus.incoming: 0,
        ContactStatus.accepted: 1,
        ContactStatus.pending: 2,
      };
      final cmp = order[a.status]!.compareTo(order[b.status]!);
      if (cmp != 0) return cmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<ContactItemEntity?> getById(String userId) async {
    final raw = _box.get(userId);
    if (raw == null) return null;
    return _decode(raw);
  }

  Future<void> upsert(ContactItemEntity item) async {
    await _box.put(item.userId, jsonEncode(item.toJson()));
  }

  Future<void> remove(String userId) async {
    await _box.delete(userId);
  }

  Stream<List<ContactItemEntity>> watchAll() {
    final controller = StreamController<List<ContactItemEntity>>.broadcast();
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

  ContactItemEntity? _decode(String raw) {
    try {
      return ContactItemEntity.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
