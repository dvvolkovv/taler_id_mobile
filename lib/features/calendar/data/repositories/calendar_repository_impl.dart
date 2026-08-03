import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/outbox_op.dart';
import '../../../../core/storage/outbox_queue.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/repositories/i_calendar_repository.dart';
import '../../../notes/domain/entities/note_entity.dart' show ConflictResolution;
import '../datasources/calendar_local_datasource.dart';
import '../datasources/calendar_remote_datasource.dart';

class CalendarRepositoryImpl implements ICalendarRepository {
  final CalendarLocalDataSource _local;
  final CalendarRemoteDataSource _remote;
  final OutboxQueue _outbox;
  final Uuid _uuid = const Uuid();

  CalendarRepositoryImpl({
    required CalendarLocalDataSource local,
    required CalendarRemoteDataSource remote,
    required OutboxQueue outbox,
  })  : _local = local,
        _remote = remote,
        _outbox = outbox;

  @override
  Stream<List<CalendarEventEntity>> watchAll() => _local.watchAll();

  @override
  Future<void> refresh({DateTime? from, DateTime? to}) async {
    final fromDate =
        (from ?? DateTime.now().subtract(const Duration(days: 30))).toUtc();
    final toDate =
        (to ?? DateTime.now().add(const Duration(days: 90))).toUtc();
    try {
      final remoteList = await _remote.getEvents(
        from: fromDate.toIso8601String(),
        to: toDate.toIso8601String(),
      );
      // Deletions still in the outbox (not yet replayed): the server still
      // returns these events, so upserting them would resurrect a just-deleted
      // event on the next refresh (the reappear-after-tab-switch bug). Skip
      // them until the delete op replays and the server stops returning them.
      final pendingDeleteIds = (await _outbox.pending())
          .where((o) => o.feature == 'calendar' && o.op == OutboxOpKind.delete)
          .map((o) => o.entityId)
          .toSet();
      final remoteIds = remoteList
          .map((m) => m['id'] as String)
          .where((id) => !pendingDeleteIds.contains(id))
          .toSet();
      final localAll = await _local.getAll();
      for (final r in remoteList) {
        final entity = _entityFromServerJson(r);
        if (pendingDeleteIds.contains(entity.id)) continue; // deletion in flight
        final existing = await _local.getById(entity.id);
        if (existing != null && existing.localPending) continue;
        await _local.upsert(entity);
      }
      for (final l in localAll) {
        if (l.localPending) continue;
        final inWindow =
            !l.startAt.isBefore(fromDate) && !l.startAt.isAfter(toDate);
        if (inWindow && !remoteIds.contains(l.id)) {
          await _local.remove(l.id);
        }
      }
    } catch (_) {
      // offline / failure → leave local intact
    }
  }

  @override
  Future<CalendarEventEntity> create(CalendarEventEntity draft) async {
    final id = draft.id.isEmpty ? _uuid.v4() : draft.id;
    final now = DateTime.now().toUtc();
    final event = draft.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
      localPending: true,
    );
    await _local.upsert(event);
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'calendar',
      op: OutboxOpKind.create,
      entityId: id,
      payload: _toServerJson(event),
      createdAt: now,
    ));
    return event;
  }

  @override
  Future<CalendarEventEntity> update(
    String id, {
    String? title,
    String? description,
    CalendarEventType? type,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    DateTime? reminderAt,
    String? displayTime,
    Map<String, dynamic>? recurrence,
    List<String>? contactIds,
  }) async {
    final current = await _local.getById(id);
    if (current == null) throw StateError('Event $id not in local store');

    final next = current.copyWith(
      title: title ?? current.title,
      description: description ?? current.description,
      type: type ?? current.type,
      startAt: startAt ?? current.startAt,
      endAt: endAt ?? current.endAt,
      allDay: allDay ?? current.allDay,
      reminderAt: reminderAt ?? current.reminderAt,
      displayTime: displayTime ?? current.displayTime,
      recurrence: recurrence ?? current.recurrence,
      contactIds: contactIds ?? current.contactIds,
      localPending: true,
    );
    await _local.upsert(next);

    final partialPayload = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type.name.toUpperCase(),
      if (startAt != null) 'startAt': startAt.toUtc().toIso8601String(),
      if (endAt != null) 'endAt': endAt.toUtc().toIso8601String(),
      if (allDay != null) 'allDay': allDay,
      if (reminderAt != null)
        'reminderAt': reminderAt.toUtc().toIso8601String(),
      if (displayTime != null) 'displayTime': displayTime,
      if (recurrence != null) 'recurrence': recurrence,
      if (contactIds != null) 'contactIds': contactIds,
    };

    final existingOps = await _outbox.pending();
    final pendingForThis = existingOps.where((o) => o.entityId == id).toList();

    OutboxOp? pendingCreate;
    for (final o in pendingForThis) {
      if (o.op == OutboxOpKind.create) {
        pendingCreate = o;
        break;
      }
    }
    if (pendingCreate != null) {
      // Squash: merge update into the pending create payload
      final merged = Map<String, dynamic>.from(pendingCreate.payload ?? {});
      merged.addAll(partialPayload);
      await _outbox.remove(pendingCreate.opId);
      await _outbox.enqueue(pendingCreate.copyWith(payload: merged));
      return next;
    }

    // Remove any pending update ops for this entity
    for (final op in pendingForThis) {
      if (op.op == OutboxOpKind.update) {
        await _outbox.remove(op.opId);
      }
    }

    // Enqueue new update op with OCC expectedUpdatedAt
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'calendar',
      op: OutboxOpKind.update,
      entityId: id,
      payload: partialPayload,
      expectedUpdatedAt: current.updatedAt,
      createdAt: DateTime.now().toUtc(),
    ));
    return next;
  }

  @override
  Future<void> delete(String id) async {
    final existingOps = await _outbox.pending();
    final pendingForThis = existingOps.where((o) => o.entityId == id).toList();

    OutboxOp? pendingCreate;
    for (final o in pendingForThis) {
      if (o.op == OutboxOpKind.create) {
        pendingCreate = o;
        break;
      }
    }

    if (pendingCreate != null) {
      // Never synced → drop everything, no server delete needed
      for (final op in pendingForThis) {
        await _outbox.remove(op.opId);
      }
      await _local.remove(id);
      return;
    }

    // Remove stale update ops
    for (final op in pendingForThis) {
      if (op.op == OutboxOpKind.update) {
        await _outbox.remove(op.opId);
      }
    }

    await _local.remove(id);
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'calendar',
      op: OutboxOpKind.delete,
      entityId: id,
      createdAt: DateTime.now().toUtc(),
    ));
  }

  @override
  Future<void> resolveConflict(String id, ConflictResolution choice) async {
    final event = await _local.getById(id);
    if (event == null || event.conflictedWith == null) return;
    final server = event.conflictedWith!;

    final ops = await _outbox.pending();
    OutboxOp? conflictOp;
    for (final o in ops) {
      if (o.entityId == id && o.status == OutboxOpStatus.failedConflict) {
        conflictOp = o;
        break;
      }
    }

    switch (choice) {
      case ConflictResolution.keepMine:
        if (conflictOp != null) {
          final serverUpdatedAt =
              DateTime.parse(server['updatedAt'] as String);
          await _outbox.remove(conflictOp.opId);
          await _outbox.enqueue(OutboxOp(
            opId: _uuid.v4(),
            feature: 'calendar',
            op: OutboxOpKind.update,
            entityId: id,
            payload: conflictOp.payload,
            expectedUpdatedAt: serverUpdatedAt,
            createdAt: DateTime.now().toUtc(),
          ));
        }
        await _local.upsert(event.copyWith(conflictedWith: null));
        break;
      case ConflictResolution.acceptServer:
        if (conflictOp != null) {
          await _outbox.remove(conflictOp.opId);
        }
        await _local.upsert(_entityFromServerJson(server));
        break;
    }
  }

  @override
  Stream<int> watchPendingCount() async* {
    yield (await _local.getAll()).where((e) => e.localPending).length;
    await for (final list in _local.watchAll()) {
      yield list.where((e) => e.localPending).length;
    }
  }

  @override
  Stream<int> watchConflictCount() async* {
    yield (await _local.getAll()).where((e) => e.conflictedWith != null).length;
    await for (final list in _local.watchAll()) {
      yield list.where((e) => e.conflictedWith != null).length;
    }
  }

  Map<String, dynamic> _toServerJson(CalendarEventEntity e) {
    return {
      'title': e.title,
      if (e.description != null) 'description': e.description,
      'type': e.type.name.toUpperCase(),
      'startAt': e.startAt.toUtc().toIso8601String(),
      if (e.endAt != null) 'endAt': e.endAt!.toUtc().toIso8601String(),
      'allDay': e.allDay,
      if (e.reminderAt != null)
        'reminderAt': e.reminderAt!.toUtc().toIso8601String(),
      if (e.displayTime != null) 'displayTime': e.displayTime,
      if (e.recurrence != null) 'recurrence': e.recurrence,
      'contactIds': e.contactIds,
      'createdBy': e.createdBy,
    };
  }

  CalendarEventEntity _entityFromServerJson(Map<String, dynamic> json) {
    final t = (json['type'] as String? ?? 'EVENT').toUpperCase();
    final typeEnum = CalendarEventType.values.firstWhere(
      (v) => v.name.toUpperCase() == t,
      orElse: () => CalendarEventType.event,
    );
    return CalendarEventEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: typeEnum,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt:
          json['endAt'] != null ? DateTime.parse(json['endAt'] as String) : null,
      allDay: (json['allDay'] as bool?) ?? false,
      reminderAt: json['reminderAt'] != null
          ? DateTime.parse(json['reminderAt'] as String)
          : null,
      reminderSent: (json['reminderSent'] as bool?) ?? false,
      displayTime: json['displayTime'] as String?,
      recurrence: json['recurrence'] is Map
          ? Map<String, dynamic>.from(json['recurrence'] as Map)
          : null,
      contactIds:
          (json['contactIds'] as List?)?.cast<String>() ?? const <String>[],
      createdBy: json['createdBy'] as String? ?? 'MANUAL',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      localPending: false,
      conflictedWith: null,
    );
  }
}
