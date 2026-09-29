import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/core/storage/outbox_queue.dart';
import 'package:taler_id_mobile/features/calendar/data/datasources/calendar_local_datasource.dart';
import 'package:taler_id_mobile/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:taler_id_mobile/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:taler_id_mobile/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:taler_id_mobile/features/notes/domain/entities/note_entity.dart'
    show ConflictResolution;

class _MockRemote extends Mock implements CalendarRemoteDataSource {}

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
  @override
  Future<String?> getApplicationSupportPath() async => dir;
  @override
  Future<String?> getTemporaryPath() async => dir;
}

CalendarEventEntity ev(String id,
        {DateTime? updatedAt, bool pending = false}) =>
    CalendarEventEntity(
      id: id,
      title: 'T-$id',
      startAt: DateTime.parse('2026-05-14T10:00:00Z'),
      createdAt: DateTime.parse('2026-05-14T09:00:00Z'),
      updatedAt: updatedAt ?? DateTime.parse('2026-05-14T09:00:00Z'),
      localPending: pending,
    );

void main() {
  late Directory tempDir;
  late CalendarLocalDataSource local;
  late OutboxQueue queue;
  late _MockRemote remote;
  late CalendarRepositoryImpl repo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('cal_repo_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(CalendarLocalDataSource.boxName);
    await Hive.openBox<String>(OutboxQueue.boxName);
    local = CalendarLocalDataSource();
    queue = OutboxQueue();
    remote = _MockRemote();
    repo =
        CalendarRepositoryImpl(local: local, remote: remote, outbox: queue);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('create writes local with localPending=true and enqueues outbox op',
      () async {
    final draft = ev('new-1');
    final n = await repo.create(draft);
    expect(n.localPending, true);
    final list = await local.getAll();
    expect(list.length, 1);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.create);
    expect(ops[0].entityId, draft.id);
    expect(ops[0].feature, 'calendar');
  });

  test(
      'update on a locally-pending create mutates the create payload (no extra op)',
      () async {
    final n = await repo.create(ev('e1'));
    await repo.update(n.id, title: 'changed');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.create);
    expect(ops[0].payload!['title'], 'changed');
  });

  test(
      'update on a synced event enqueues an update op with expectedUpdatedAt',
      () async {
    final synced =
        ev('e1', updatedAt: DateTime.parse('2026-05-14T08:00:00Z'));
    await local.upsert(synced);
    await repo.update('e1', title: 'new-title');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.update);
    expect(ops[0].expectedUpdatedAt, synced.updatedAt);
    final localNow = await local.getById('e1');
    expect(localNow!.title, 'new-title');
    expect(localNow.localPending, true);
  });

  test('delete on a locally-pending create drops both local and outbox',
      () async {
    final n = await repo.create(ev('e1'));
    await repo.delete(n.id);
    expect((await local.getAll()).isEmpty, true);
    expect((await queue.pending()).isEmpty, true);
  });

  test('delete on a synced event enqueues delete + removes from local',
      () async {
    await local.upsert(ev('e1'));
    await repo.delete('e1');
    expect((await local.getAll()).isEmpty, true);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.delete);
    expect(ops[0].entityId, 'e1');
  });

  test(
      'resolveConflict KEEP_MINE replaces conflict op with fresh update using server updatedAt',
      () async {
    final localEv = ev('e1', pending: true).copyWith(conflictedWith: {
      'id': 'e1',
      'title': 'srv-title',
      'startAt': '2026-05-14T10:00:00.000Z',
      'createdAt': '2026-05-14T09:00:00.000Z',
      'updatedAt': '2026-05-14T10:10:00.000Z',
      'type': 'EVENT',
    });
    await local.upsert(localEv);
    await queue.enqueue(OutboxOp(
      opId: 'conflict-op',
      feature: 'calendar',
      op: OutboxOpKind.update,
      entityId: 'e1',
      payload: {'title': 'mine'},
      status: OutboxOpStatus.failedConflict,
      createdAt: DateTime.now(),
    ));

    await repo.resolveConflict('e1', ConflictResolution.keepMine);

    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].opId, isNot('conflict-op'));
    expect(ops[0].status, OutboxOpStatus.pending);
    expect(ops[0].expectedUpdatedAt,
        DateTime.parse('2026-05-14T10:10:00.000Z'));
    final localNow = await local.getById('e1');
    expect(localNow!.conflictedWith, isNull);
  });

  // ── Durable real-Task mutations (feature `task`) — fix for the "ghost" bug
  // where a lost/direct delete left a task the app hid but the server kept. ──

  test('deleteTask removes the view entity optimistically + enqueues a task delete op',
      () async {
    await local.upsert(ev('task:t-1:2026-09-29'));
    await repo.deleteTask(taskId: 't-1', viewId: 'task:t-1:2026-09-29');
    expect((await local.getAll()).isEmpty, true);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].feature, 'task');
    expect(ops[0].op, OutboxOpKind.delete);
    expect(ops[0].entityId, 't-1');
  });

  test('setTaskStatus done removes the view entity + enqueues a task update op with occurrenceDate',
      () async {
    await local.upsert(ev('task:t-1:2026-09-29'));
    await repo.setTaskStatus(
      taskId: 't-1',
      status: 'done',
      occurrenceDate: '2026-09-29',
      viewId: 'task:t-1:2026-09-29',
    );
    expect((await local.getAll()).isEmpty, true);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].feature, 'task');
    expect(ops[0].op, OutboxOpKind.update);
    expect(ops[0].entityId, 't-1');
    expect(ops[0].payload!['status'], 'done');
    expect(ops[0].payload!['occurrenceDate'], '2026-09-29');
  });

  test('deleteTask supersedes a queued status op for the same task', () async {
    await repo.setTaskStatus(
        taskId: 't-1', status: 'done', viewId: 'task:t-1:2026-09-29');
    await repo.deleteTask(taskId: 't-1', viewId: 'task:t-1:2026-09-29');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.delete);
  });

  test('refresh does NOT resurrect a task while its delete op is in flight',
      () async {
    final now = DateTime.now().toUtc();
    final taskJson = <String, dynamic>{
      'id': 'task:t-1:2026-09-29',
      'title': 'Открыть счет МТС',
      'type': 'task',
      'startAt': now.toIso8601String(),
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    when(() => remote.getEvents(
          from: any(named: 'from'),
          to: any(named: 'to'),
        )).thenAnswer((_) async => [taskJson]);
    // Delete op in flight — server still returns the task until it replays.
    await queue.enqueue(OutboxOp(
      opId: 'del-1',
      feature: 'task',
      op: OutboxOpKind.delete,
      entityId: 't-1',
      createdAt: now,
    ));

    await repo.refresh();

    // The just-deleted task must not reappear.
    expect((await local.getAll()).where((e) => e.id.startsWith('task:')).isEmpty, true);
  });

  test('resolveConflict ACCEPT_SERVER overwrites local + drops op', () async {
    final localEv = ev('e1', pending: true).copyWith(conflictedWith: {
      'id': 'e1',
      'title': 'srv-title',
      'startAt': '2026-05-14T10:00:00.000Z',
      'createdAt': '2026-05-14T09:00:00.000Z',
      'updatedAt': '2026-05-14T10:10:00.000Z',
      'type': 'EVENT',
    });
    await local.upsert(localEv);
    await queue.enqueue(OutboxOp(
      opId: 'conflict-op',
      feature: 'calendar',
      op: OutboxOpKind.update,
      entityId: 'e1',
      payload: {'title': 'mine'},
      status: OutboxOpStatus.failedConflict,
      createdAt: DateTime.now(),
    ));

    await repo.resolveConflict('e1', ConflictResolution.acceptServer);

    expect((await queue.pending()).isEmpty, true);
    final localNow = await local.getById('e1');
    expect(localNow!.title, 'srv-title');
    expect(localNow.localPending, false);
    expect(localNow.conflictedWith, isNull);
  });
}
