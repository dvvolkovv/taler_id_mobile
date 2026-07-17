import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/core/storage/outbox_queue.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:taler_id_mobile/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:taler_id_mobile/features/notes/domain/entities/note_entity.dart';

// User report 2026-07-17: "не с первого раза удаляются заметки". The refresh
// guard (7f12aef) only protects ids while their DELETE op is still queued —
// once the op drains, a stale server list resurrects the note. Tombstones
// close the whole class.
class _FakeRemote implements NotesRemoteDataSource {
  List<Map<String, dynamic>> remoteList = [];

  @override
  Future<List<Map<String, dynamic>>> getAll({int limit = 50, int offset = 0}) async =>
      remoteList;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late Directory tempDir;
  late NotesLocalDataSource local;
  late _FakeRemote remote;
  late OutboxQueue outbox;
  late NotesRepositoryImpl repo;

  Map<String, dynamic> serverJson(String id) => {
        'id': id,
        'title': 'T',
        'content': 'C',
        'source': 'MANUAL',
        'createdAt': '2026-07-01T10:00:00.000Z',
        'updatedAt': '2026-07-01T10:00:00.000Z',
      };

  NoteEntity note(String id) => NoteEntity(
        id: id,
        title: 'T',
        content: 'C',
        source: NoteSource.manual,
        createdAt: DateTime.utc(2026, 7, 1, 10),
        updatedAt: DateTime.utc(2026, 7, 1, 10),
        localPending: false,
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('notes_tomb_');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(NotesLocalDataSource.boxName);
    await Hive.openBox<String>(NotesLocalDataSource.tombstoneBoxName);
    await Hive.openBox<String>(OutboxQueue.boxName);
    local = NotesLocalDataSource();
    remote = _FakeRemote();
    outbox = OutboxQueue();
    repo = NotesRepositoryImpl(local: local, remote: remote, outbox: outbox);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('refresh does not resurrect a deleted note after its DELETE op drained',
      () async {
    await local.upsert(note('n1'));
    remote.remoteList = [serverJson('n1')];

    await repo.delete('n1');
    expect(await local.getById('n1'), isNull);

    // Simulate the outbox drain completing (DELETE reached the server) …
    for (final op in await outbox.pending()) {
      await outbox.remove(op.opId);
    }
    // … but the server list is stale and still contains the note.
    await repo.refresh();

    expect(await local.getById('n1'), isNull,
        reason: 'stale server list must not resurrect a tombstoned note');
  });

  test('delete while CREATE op is inflight still enqueues a DELETE', () async {
    final created = await repo.create('T', 'C');
    final createOp = (await outbox.pending())
        .firstWhere((o) => o.op == OutboxOpKind.create);
    await outbox.markInflight(createOp.opId);

    await repo.delete(created.id);

    final ops = await outbox.pending();
    expect(
      ops.any((o) => o.op == OutboxOpKind.delete && o.entityId == created.id),
      isTrue,
      reason: 'an inflight CREATE may already be on the server — without a '
          'queued DELETE the note comes back on next refresh forever',
    );
  });

  test('fresh notes from the server still sync in', () async {
    remote.remoteList = [serverJson('n2')];
    await repo.refresh();
    expect(await local.getById('n2'), isNotNull);
  });
}
