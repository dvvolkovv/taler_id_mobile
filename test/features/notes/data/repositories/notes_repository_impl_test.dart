import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/core/storage/outbox_queue.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:taler_id_mobile/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:taler_id_mobile/features/notes/domain/entities/note_entity.dart';

class _MockRemote extends Mock implements NotesRemoteDataSource {}

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override Future<String?> getApplicationDocumentsPath() async => dir;
  @override Future<String?> getApplicationSupportPath() async => dir;
  @override Future<String?> getTemporaryPath() async => dir;
}

void main() {
  late Directory tempDir;
  late NotesLocalDataSource local;
  late OutboxQueue queue;
  late _MockRemote remote;
  late NotesRepositoryImpl repo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('notes_repo_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(NotesLocalDataSource.boxName);
    await Hive.openBox<String>(OutboxQueue.boxName);
    local = NotesLocalDataSource();
    queue = OutboxQueue();
    remote = _MockRemote();
    repo = NotesRepositoryImpl(local: local, remote: remote, outbox: queue);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('create writes local with localPending=true and enqueues outbox op', () async {
    final n = await repo.create('t', 'c');
    expect(n.localPending, true);
    final localList = await local.getAll();
    expect(localList.length, 1);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.create);
    expect(ops[0].entityId, n.id);
  });

  test('update on a locally-pending create updates the create payload (no extra op)', () async {
    final n = await repo.create('orig', 'c');
    await repo.update(n.id, title: 'changed');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.create);
    expect(ops[0].payload!['title'], 'changed');
  });

  test('update on a synced note enqueues an update op with expectedUpdatedAt', () async {
    final synced = NoteEntity(
      id: 'n-1',
      title: 'a',
      content: 'b',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
    );
    await local.upsert(synced);
    await repo.update('n-1', title: 'a2');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.update);
    expect(ops[0].expectedUpdatedAt, synced.updatedAt);
    final localNow = await local.getById('n-1');
    expect(localNow!.title, 'a2');
    expect(localNow.localPending, true);
  });

  test('delete on a locally-pending create drops both local and outbox', () async {
    final n = await repo.create('t', 'c');
    await repo.delete(n.id);
    expect((await local.getAll()).isEmpty, true);
    expect((await queue.pending()).isEmpty, true);
  });

  test('delete on a synced note enqueues delete + removes from local', () async {
    final synced = NoteEntity(
      id: 'n-1',
      title: 'a',
      content: 'b',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
    );
    await local.upsert(synced);
    await repo.delete('n-1');
    expect((await local.getAll()).isEmpty, true);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.delete);
    expect(ops[0].entityId, 'n-1');
  });

  test('resolveConflict KEEP_MINE replaces conflict op with fresh update using server updatedAt', () async {
    final localNote = NoteEntity(
      id: 'n-1',
      title: 'mine',
      content: 'mine-content',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
      localPending: true,
      conflictedWith: {
        'id': 'n-1',
        'title': 'server',
        'content': 'server-content',
        'updatedAt': '2026-05-13T10:10:00.000Z',
      },
    );
    await local.upsert(localNote);
    await queue.enqueue(OutboxOp(
      opId: 'conflict-op',
      feature: 'notes',
      op: OutboxOpKind.update,
      entityId: 'n-1',
      payload: {'title': 'mine', 'content': 'mine-content'},
      status: OutboxOpStatus.failedConflict,
      createdAt: DateTime.now(),
    ));

    await repo.resolveConflict('n-1', ConflictResolution.keepMine);

    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].opId, isNot('conflict-op'));
    expect(ops[0].status, OutboxOpStatus.pending);
    expect(ops[0].expectedUpdatedAt, DateTime.parse('2026-05-13T10:10:00.000Z'));
    final localNow = await local.getById('n-1');
    expect(localNow!.conflictedWith, isNull);
  });

  test('resolveConflict ACCEPT_SERVER overwrites local + drops op', () async {
    final localNote = NoteEntity(
      id: 'n-1',
      title: 'mine',
      content: 'mine-content',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
      localPending: true,
      conflictedWith: {
        'id': 'n-1',
        'title': 'server',
        'content': 'server-content',
        'createdAt': '2026-05-13T10:00:00.000Z',
        'updatedAt': '2026-05-13T10:10:00.000Z',
        'source': 'MANUAL',
      },
    );
    await local.upsert(localNote);
    await queue.enqueue(OutboxOp(
      opId: 'conflict-op',
      feature: 'notes',
      op: OutboxOpKind.update,
      entityId: 'n-1',
      payload: {'title': 'mine'},
      status: OutboxOpStatus.failedConflict,
      createdAt: DateTime.now(),
    ));

    await repo.resolveConflict('n-1', ConflictResolution.acceptServer);

    expect((await queue.pending()).isEmpty, true);
    final localNow = await local.getById('n-1');
    expect(localNow!.title, 'server');
    expect(localNow.localPending, false);
    expect(localNow.conflictedWith, isNull);
  });
}
