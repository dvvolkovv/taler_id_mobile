import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/outbox_op.dart';
import '../../../../core/storage/outbox_queue.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/i_notes_repository.dart';
import '../datasources/notes_local_datasource.dart';
import '../datasources/notes_remote_datasource.dart';

class NotesRepositoryImpl implements INotesRepository {
  final NotesLocalDataSource _local;
  final NotesRemoteDataSource _remote;
  final OutboxQueue _outbox;
  final Uuid _uuid = const Uuid();

  NotesRepositoryImpl({
    required NotesLocalDataSource local,
    required NotesRemoteDataSource remote,
    required OutboxQueue outbox,
  })  : _local = local,
        _remote = remote,
        _outbox = outbox;

  @override
  Stream<List<NoteEntity>> watchAll() => _local.watchAll();

  @override
  Future<void> refresh() async {
    try {
      // Entities that have an outbox op still in flight (pending or inflight)
      // must NOT be touched by the server-merge below: the most common case
      // is a queued DELETE whose HTTP call hasn't reached the server yet —
      // upserting the server copy here would resurrect the deleted note and
      // the user would see it reappear on pull-to-refresh. See incident
      // 2026-06-16. Squashed/dead ops aren't filtered: a dead DELETE means
      // the server kept the note and the user should see it back.
      final inFlightIds = (await _outbox.pending())
          .where((o) =>
              o.feature == 'notes' &&
              (o.status == OutboxOpStatus.pending ||
                  o.status == OutboxOpStatus.inflight))
          .map((o) => o.entityId)
          .toSet();

      final remoteList = await _remote.getAll(limit: 200);
      final remoteIds = remoteList.map((m) => m['id'] as String).toSet();
      final localList = await _local.getAll();
      for (final r in remoteList) {
        final entity = _entityFromServerJson(r);
        if (inFlightIds.contains(entity.id)) continue;
        final localNote = await _local.getById(entity.id);
        if (localNote != null && localNote.localPending) {
          // preserve local in-flight edits
          continue;
        }
        await _local.upsert(entity);
      }
      for (final l in localList) {
        if (!remoteIds.contains(l.id) &&
            !l.localPending &&
            !inFlightIds.contains(l.id)) {
          await _local.remove(l.id);
        }
      }
    } catch (_) {
      // offline / failure → ignore, local data stays
    }
  }

  @override
  Future<NoteEntity> create(String title, String content,
      {NoteSource source = NoteSource.manual}) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final n = NoteEntity(
      id: id,
      title: title,
      content: content,
      source: source,
      createdAt: now,
      updatedAt: now,
      localPending: true,
    );
    await _local.upsert(n);
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'notes',
      op: OutboxOpKind.create,
      entityId: id,
      payload: {
        'title': title,
        'content': content,
        'source': source == NoteSource.manual ? 'MANUAL' : 'ASSISTANT',
      },
      createdAt: now,
    ));
    return n;
  }

  @override
  Future<NoteEntity> update(String id, {String? title, String? content}) async {
    final current = await _local.getById(id);
    if (current == null) throw StateError('Note $id not in local store');
    final next = current.copyWith(
      title: title ?? current.title,
      content: content ?? current.content,
      localPending: true,
    );
    await _local.upsert(next);

    final existingOps = await _outbox.pending();
    final pendingForThis = existingOps.where((o) => o.entityId == id).toList();

    // Squash: if pending create exists, update its payload (no new op)
    OutboxOp? pendingCreate;
    for (final o in pendingForThis) {
      if (o.op == OutboxOpKind.create) {
        pendingCreate = o;
        break;
      }
    }
    if (pendingCreate != null) {
      final mergedPayload = Map<String, dynamic>.from(pendingCreate.payload ?? {});
      if (title != null) mergedPayload['title'] = title;
      if (content != null) mergedPayload['content'] = content;
      await _outbox.remove(pendingCreate.opId);
      await _outbox.enqueue(pendingCreate.copyWith(payload: mergedPayload));
      return next;
    }
    // Squash: replace any pending update for this entity
    for (final op in pendingForThis) {
      if (op.op == OutboxOpKind.update) {
        await _outbox.remove(op.opId);
      }
    }
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'notes',
      op: OutboxOpKind.update,
      entityId: id,
      payload: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
      },
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
      // never reached server — drop everything for this id
      for (final op in pendingForThis) {
        await _outbox.remove(op.opId);
      }
      await _local.remove(id);
      return;
    }
    // squash any pending update (now obsolete)
    for (final op in pendingForThis) {
      if (op.op == OutboxOpKind.update) {
        await _outbox.remove(op.opId);
      }
    }
    await _local.remove(id);
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'notes',
      op: OutboxOpKind.delete,
      entityId: id,
      createdAt: DateTime.now().toUtc(),
    ));
  }

  @override
  Future<void> resolveConflict(String id, ConflictResolution choice) async {
    final note = await _local.getById(id);
    if (note == null || note.conflictedWith == null) return;
    final server = note.conflictedWith!;

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
          final serverUpdatedAt = DateTime.parse(server['updatedAt'] as String);
          await _outbox.remove(conflictOp.opId);
          await _outbox.enqueue(OutboxOp(
            opId: _uuid.v4(),
            feature: 'notes',
            op: OutboxOpKind.update,
            entityId: id,
            payload: conflictOp.payload,
            expectedUpdatedAt: serverUpdatedAt,
            createdAt: DateTime.now().toUtc(),
          ));
        }
        await _local.upsert(note.copyWith(conflictedWith: null));
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
    yield (await _local.getAll()).where((n) => n.localPending).length;
    await for (final list in _local.watchAll()) {
      yield list.where((n) => n.localPending).length;
    }
  }

  @override
  Stream<int> watchConflictCount() async* {
    yield (await _local.getAll()).where((n) => n.conflictedWith != null).length;
    await for (final list in _local.watchAll()) {
      yield list.where((n) => n.conflictedWith != null).length;
    }
  }

  NoteEntity _entityFromServerJson(Map<String, dynamic> json) {
    final src = json['source'] as String? ?? 'MANUAL';
    return NoteEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      source: src == 'ASSISTANT' ? NoteSource.assistant : NoteSource.manual,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      localPending: false,
      conflictedWith: null,
    );
  }
}
