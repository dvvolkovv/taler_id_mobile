import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_handler.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_service.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/core/storage/outbox_queue.dart';

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

class _FakeHandler implements OutboxReplayHandler {
  @override
  final String feature;
  final List<OutboxReplayResult> resultsQueue;
  final List<OutboxOp> seen = [];
  _FakeHandler(this.feature, this.resultsQueue);
  @override
  Future<OutboxReplayResult> replay(OutboxOp op) async {
    seen.add(op);
    return resultsQueue.removeAt(0);
  }
}

OutboxOp op({String id = 'a', DateTime? createdAt, int attempts = 0}) => OutboxOp(
      opId: id,
      feature: 'notes',
      op: OutboxOpKind.create,
      entityId: 'n-$id',
      createdAt: createdAt ?? DateTime.parse('2026-05-13T10:00:00Z'),
      attempts: attempts,
    );

void main() {
  late Directory tempDir;
  late OutboxQueue queue;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('outbox_replay_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(OutboxQueue.boxName);
    queue = OutboxQueue();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('drain calls handler for each pending op and removes on success', () async {
    final handler = _FakeHandler('notes', [
      OutboxReplayResult.success(),
      OutboxReplayResult.success(),
    ]);
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(handler);
    await queue.enqueue(op(id: 'a', createdAt: DateTime.parse('2026-05-13T10:00:00Z')));
    await queue.enqueue(op(id: 'b', createdAt: DateTime.parse('2026-05-13T10:01:00Z')));

    await svc.drain();

    expect(handler.seen.map((o) => o.opId).toList(), ['a', 'b']);
    expect((await queue.pending()).isEmpty, true);
  });

  test('retry result keeps the op pending with incremented attempts', () async {
    final handler = _FakeHandler('notes', [
      OutboxReplayResult.retry(error: 'network'),
    ]);
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(handler);
    await queue.enqueue(op());

    await svc.drain();

    final remaining = await queue.pending();
    expect(remaining.length, 1);
    expect(remaining[0].status, OutboxOpStatus.pending);
    expect(remaining[0].attempts, 1);
    expect(remaining[0].lastError, 'network');
  });

  test('conflict result transitions op to failedConflict with serverData', () async {
    final handler = _FakeHandler('notes', [
      OutboxReplayResult.conflict(serverData: {'title': 'srv'}),
    ]);
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(handler);
    await queue.enqueue(op());

    await svc.drain();

    final remaining = await queue.pending();
    expect(remaining[0].status, OutboxOpStatus.failedConflict);
    expect(remaining[0].serverData, {'title': 'srv'});
  });

  test('dead result transitions op to failedDead', () async {
    final handler = _FakeHandler('notes', [
      OutboxReplayResult.dead(error: 'bad request'),
    ]);
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(handler);
    await queue.enqueue(op());

    await svc.drain();

    expect((await queue.pending())[0].status, OutboxOpStatus.failedDead);
  });

  test('unknown feature → op marked dead with "no handler" error', () async {
    final svc = OutboxReplayService(queue: queue);
    await queue.enqueue(op());
    await svc.drain();
    final remaining = await queue.pending();
    expect(remaining[0].status, OutboxOpStatus.failedDead);
    expect(remaining[0].lastError, contains('no handler'));
  });

  test('attempts >= 10 causes auto-dead before calling handler', () async {
    final handler = _FakeHandler('notes', [OutboxReplayResult.retry(error: 'x')]);
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(handler);
    await queue.enqueue(op(attempts: 9));
    await svc.drain();
    final remaining = await queue.pending();
    expect(remaining[0].status, OutboxOpStatus.failedDead);
  });

  test('drain is single-flight: concurrent calls do not double-replay', () async {
    final handler = _FakeHandler('notes', [OutboxReplayResult.success()]);
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(handler);
    await queue.enqueue(op());

    final f1 = svc.drain();
    final f2 = svc.drain();
    await Future.wait([f1, f2]);

    expect(handler.seen.length, 1);
  });
}
