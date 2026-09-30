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
      // Only ops that are still live (not permanently dead) hide their entity —
      // a dead op lets the item reappear so the true server state wins.
      final pendingOps = (await _outbox.pending())
          .where((o) => o.status != OutboxOpStatus.failedDead)
          .toList();
      final pendingDeleteIds = pendingOps
          .where((o) => o.feature == 'calendar' && o.op == OutboxOpKind.delete)
          .map((o) => o.entityId)
          .toSet();
      // Real-Task ops (feature `task`) hide the synthetic calendar entity
      // "task:{taskId}:{YYYY-MM-DD}" while a delete/status write is in flight, so
      // the just-deleted/completed task doesn't flash back until replay confirms.
      final taskDeleteIds = <String>{}; // whole task gone → hide every occurrence
      final taskStatusAllIds = <String>{}; // one-off status change → hide all
      final taskStatusDates = <String>{}; // routine day → hide "task:id:date"
      // Field edits (feature `task`, update op WITHOUT a 'status' key) are NOT
      // hidden — they're overlaid onto the server occurrence at upsert time so
      // the edited fields show until replay, then converge to server truth with
      // no stale row (the view id encodes the due date, so a day-moving edit
      // would otherwise leave a ghost — see updateTask). taskId → patched fields.
      final taskFieldPatches = <String, Map<String, dynamic>>{};
      for (final o in pendingOps) {
        if (o.feature != 'task') continue;
        if (o.op == OutboxOpKind.delete) {
          taskDeleteIds.add(o.entityId);
        } else if (o.op == OutboxOpKind.update) {
          final payload = o.payload ?? const {};
          if (payload.containsKey('status')) {
            final occ = payload['occurrenceDate'] as String?;
            if (occ != null) {
              taskStatusDates.add('task:${o.entityId}:$occ');
            } else {
              taskStatusAllIds.add(o.entityId);
            }
          } else {
            // Field edit: later op wins if two are queued for one task.
            taskFieldPatches[o.entityId] = Map<String, dynamic>.from(payload);
          }
        }
      }
      bool taskHidden(String entityId) {
        final p = _parseTaskViewId(entityId);
        if (p == null) return false;
        final realId = p.$1;
        if (taskDeleteIds.contains(realId)) return true;
        if (taskStatusAllIds.contains(realId)) return true;
        if (taskStatusDates.contains(entityId)) return true;
        return false;
      }

      final remoteIds = remoteList
          .map((m) => m['id'] as String)
          .where((id) => !pendingDeleteIds.contains(id) && !taskHidden(id))
          .toSet();
      final localAll = await _local.getAll();
      for (final r in remoteList) {
        var entity = _entityFromServerJson(r);
        if (pendingDeleteIds.contains(entity.id)) continue; // deletion in flight
        if (taskHidden(entity.id)) continue; // task delete/status in flight
        // Overlay a pending field edit onto the server task occurrence so the
        // edit stays visible until the PATCH replays (then the server already
        // returns these values and the overlay is a no-op).
        if (taskFieldPatches.isNotEmpty) {
          final p = _parseTaskViewId(entity.id);
          final patch = p == null ? null : taskFieldPatches[p.$1];
          if (patch != null) entity = _applyTaskFieldPatch(entity, patch);
        }
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

  /// Parse a synthetic task calendar id "task:{taskId}:{YYYY-MM-DD}" →
  /// (taskId, date). Returns null for a non-task id. Mirrors the parser in
  /// the calendar screen (kept here so refresh can filter in-flight task ops).
  (String, String)? _parseTaskViewId(String id) {
    if (!id.startsWith('task:')) return null;
    final rest = id.substring(5);
    final i = rest.lastIndexOf(':');
    if (i <= 0 || i >= rest.length - 1) return null;
    return (rest.substring(0, i), rest.substring(i + 1));
  }

  @override
  Future<void> deleteTask({required String taskId, required String viewId}) async {
    // Optimistic: remove the tapped occurrence now; refresh() hides every
    // "task:$taskId:*" while the delete op is live, so the whole series drops.
    await _local.remove(viewId);
    // Drop any queued status change for the same task — a delete supersedes it.
    for (final o in await _outbox.pending()) {
      if (o.feature == 'task' && o.entityId == taskId && o.op == OutboxOpKind.update) {
        await _outbox.remove(o.opId);
      }
    }
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'task',
      op: OutboxOpKind.delete,
      entityId: taskId,
      createdAt: DateTime.now().toUtc(),
    ));
  }

  @override
  Future<void> setTaskStatus({
    required String taskId,
    required String status,
    String? occurrenceDate,
    required String viewId,
  }) async {
    // done/dropped remove the item from the active calendar view (the server
    // merge stops returning it); mirror that optimistically.
    if (status == 'done' || status == 'dropped') {
      await _local.remove(viewId);
    }
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'task',
      op: OutboxOpKind.update,
      entityId: taskId,
      payload: <String, dynamic>{
        'status': status,
        if (occurrenceDate != null) 'occurrenceDate': occurrenceDate,
      },
      createdAt: DateTime.now().toUtc(),
    ));
  }

  @override
  Future<void> updateTask({
    required String taskId,
    required String viewId,
    required Map<String, dynamic> fields,
  }) async {
    if (fields.isEmpty) return;
    // Optimism (no ghosts): patch every currently-cached occurrence of this
    // task in place — SAME ids, localPending stays false — so the edit shows at
    // once and normal refresh reconciliation can still retire a stale row after
    // a day-moving `due` change (the server switches "task:{id}:{oldDate}" for
    // "task:{id}:{newDate}" once the PATCH replays; refresh().taskFieldPatches
    // keeps the fields overlaid in the meantime). localPending is deliberately
    // NOT set: that flag protects a row from removal, which would strand the
    // old-date row as a ghost.
    for (final l in await _local.getAll()) {
      final p = _parseTaskViewId(l.id);
      if (p == null || p.$1 != taskId) continue;
      await _local.upsert(_applyTaskFieldPatch(l, fields));
    }
    // Collapse an older queued field edit for the same task — last write wins
    // (a status change is a different payload shape and is left intact).
    for (final o in await _outbox.pending()) {
      if (o.feature == 'task' &&
          o.entityId == taskId &&
          o.op == OutboxOpKind.update &&
          !(o.payload ?? const {}).containsKey('status')) {
        await _outbox.remove(o.opId);
      }
    }
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'task',
      op: OutboxOpKind.update,
      entityId: taskId,
      // No 'status' key → TaskOutboxReplayHandler routes this to PATCH /tasks/:id.
      payload: Map<String, dynamic>.from(fields),
      createdAt: DateTime.now().toUtc(),
    ));
  }

  /// Apply a task field edit (payload keys title/note/due/recurrence) onto a
  /// calendar entity. `note` maps to description, `due` to startAt; a present
  /// `recurrence` key (incl. null) sets/clears the routine. Keys absent from
  /// [fields] are left unchanged. `deadline` has no calendar-entity field, so it
  /// is not shown optimistically (still PATCHed to the server).
  CalendarEventEntity _applyTaskFieldPatch(
    CalendarEventEntity base,
    Map<String, dynamic> fields,
  ) {
    return base.copyWith(
      title: fields.containsKey('title')
          ? (fields['title'] as String? ?? base.title)
          : base.title,
      description:
          fields.containsKey('note') ? fields['note'] as String? : base.description,
      startAt: (fields.containsKey('due') && fields['due'] != null)
          ? DateTime.parse(fields['due'] as String)
          : base.startAt,
      recurrence: fields.containsKey('recurrence')
          ? (fields['recurrence'] is Map
              ? Map<String, dynamic>.from(fields['recurrence'] as Map)
              : null)
          : base.recurrence,
    );
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
      userId: (json['userId'] as String?) ??
          ((json['user'] as Map?)?['id'] as String?),
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
