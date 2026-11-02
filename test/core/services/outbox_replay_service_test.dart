import 'dart:async';
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


/// Очередь, роняющая запись результата: доказывает, что упавшая запись не уносит
/// с собой весь прогон (до фикса исключение улетало из drain и операция навсегда
/// оставалась inflight — ровно картина замороженной очереди 02.11.2026).
class _FailingWriteQueue extends OutboxQueue {
  final Set<String> failRemoveFor;
  _FailingWriteQueue(this.failRemoveFor);
  @override
  Future<void> remove(String opId) async {
    if (failRemoveFor.remove(opId)) throw StateError('disk went away');
    return super.remove(opId);
  }
}


/// Хендлер, который уходит в отправку и не возвращается: так ведёт себя прогон,
/// залипший на живом приложении 02.11.2026 (запрос ушёл, на сервере применился,
/// ответ в код не вернулся).
class _HangingHandler implements OutboxReplayHandler {
  @override
  final String feature;
  int calls = 0;
  _HangingHandler(this.feature);
  @override
  Future<OutboxReplayResult> replay(OutboxOp op) {
    calls++;
    return Completer<OutboxReplayResult>().future; // навсегда
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

  test('залипший inflight воскресает следующим прогоном, а не только на старте приложения', () async {
    final handler = _FakeHandler('notes', [OutboxReplayResult.success()]);
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(handler);
    // Операция, которую прошлый прогон пометил «отправляется» и бросил.
    await queue.enqueue(op(id: 'stuck'));
    await queue.markInflight('stuck');
    await queue.backdateAttempt('stuck', DateTime.now().subtract(const Duration(hours: 3)));

    await svc.drain();

    expect(handler.seen.map((o) => o.opId).toList(), ['stuck'],
        reason: 'зависшую операцию обязан подобрать обычный прогон');
    expect((await queue.pending()).isEmpty, true);
  });

  test('свежий inflight прогон не трогает — он может быть живым replay', () async {
    final handler = _FakeHandler('notes', [OutboxReplayResult.success()]);
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(handler);
    await queue.enqueue(op(id: 'live'));
    await queue.markInflight('live');

    await svc.drain();

    expect(handler.seen, isEmpty);
    expect((await queue.pending()).single.status, OutboxOpStatus.inflight);
  });

  test('воскрешение считает попытку, поэтому вечно висящая операция в итоге умирает', () async {
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(_FakeHandler('notes', []));
    await queue.enqueue(op(id: 'zombie', attempts: 8));
    await queue.markInflight('zombie');
    await queue.backdateAttempt('zombie', DateTime.now().subtract(const Duration(hours: 3)));

    await svc.drain();

    final after = (await queue.pending()).single;
    expect(after.status, OutboxOpStatus.failedDead,
        reason: 'иначе зависающая операция воскресала бы бесконечно');
  });

  test('упавшая запись результата не обрывает прогон: следующая операция всё равно едет', () async {
    final failing = _FailingWriteQueue({'a'});
    final handler = _FakeHandler('notes', [
      OutboxReplayResult.success(),
      OutboxReplayResult.success(),
    ]);
    final svc = OutboxReplayService(queue: failing);
    svc.registerHandler(handler);
    await failing.enqueue(op(id: 'a', createdAt: DateTime.parse('2026-05-13T10:00:00Z')));
    await failing.enqueue(op(id: 'b', createdAt: DateTime.parse('2026-05-13T10:01:00Z')));

    await svc.drain();

    expect(handler.seen.map((o) => o.opId).toList(), ['a', 'b'],
        reason: 'падение на первой не должно морозить очередь');
    final left = await failing.pending();
    expect(left.map((o) => o.opId).toList(), ['a']);
    expect(left.single.status, OutboxOpStatus.pending,
        reason: 'операция обязана остаться повторяемой, а не залипнуть в inflight');
    expect(left.single.attempts, 1);
  });

  test('периодический прогон повторяет попытку без участия пользователя', () async {
    final handler = _FakeHandler('notes', [
      OutboxReplayResult.retry(error: 'network'),
      OutboxReplayResult.success(),
    ]);
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(handler);
    await queue.enqueue(op());

    svc.startPeriodicDrain(interval: const Duration(milliseconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    svc.stopPeriodicDrain();

    expect(handler.seen.length, greaterThanOrEqualTo(2));
    expect((await queue.pending()).isEmpty, true);
  });


  test('зависший прогон не блокирует следующие навсегда', () async {
    // Единственный флаг single-flight означал: один прогон, не дошедший до конца,
    // запирает очередь до перезапуска приложения. Именно это и случилось: таймаут
    // на replay не спас, потому что зависло НЕ на нём, а флаг так и остался поднят.
    final hanging = _HangingHandler('notes');
    final svc = OutboxReplayService(
      queue: queue,
      maxDrainDuration: const Duration(milliseconds: 50),
    );
    svc.registerHandler(hanging);
    await queue.enqueue(op(id: 'a'));

    unawaited(svc.drain()); // повиснет внутри replay
    await Future<void>.delayed(const Duration(milliseconds: 120));
    // Следующий прогон обязан войти, а не выйти по флагу. Его тоже не ждём: на
    // том же хендлере он повиснет так же — важно, что он ДОШЁЛ до отправки.
    unawaited(svc.drain());
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(hanging.calls, greaterThanOrEqualTo(2),
        reason: 'повисший прогон обязан уступить дорогу следующему');
  });

  test('пока предыдущий прогон укладывается в срок, второй не лезет параллельно', () async {
    final handler = _FakeHandler('notes', [OutboxReplayResult.success()]);
    final svc = OutboxReplayService(queue: queue);
    svc.registerHandler(handler);
    await queue.enqueue(op(id: 'a'));

    await Future.wait([svc.drain(), svc.drain()]);

    expect(handler.seen.length, 1, reason: 'операция не должна уехать дважды');
  });

}
