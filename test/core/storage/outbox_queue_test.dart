import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
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

OutboxOp op({
  String opId = 'op-1',
  String feature = 'notes',
  OutboxOpKind kind = OutboxOpKind.create,
  String entityId = 'e-1',
  DateTime? createdAt,
  OutboxOpStatus status = OutboxOpStatus.pending,
  int attempts = 0,
}) =>
    OutboxOp(
      opId: opId,
      feature: feature,
      op: kind,
      entityId: entityId,
      createdAt: createdAt ?? DateTime.parse('2026-05-13T10:00:00Z'),
      status: status,
      attempts: attempts,
    );

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('outbox_queue_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(OutboxQueue.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('enqueue + pending lists the op', () async {
    final q = OutboxQueue();
    await q.enqueue(op(opId: 'a'));
    final list = await q.pending();
    expect(list.length, 1);
    expect(list[0].opId, 'a');
  });

  test('FIFO by createdAt', () async {
    final q = OutboxQueue();
    await q.enqueue(op(opId: 'b', createdAt: DateTime.parse('2026-05-13T10:02:00Z')));
    await q.enqueue(op(opId: 'a', createdAt: DateTime.parse('2026-05-13T10:01:00Z')));
    final next = await q.nextPending();
    expect(next?.opId, 'a');
  });

  test('markInflight then markPending preserves the op', () async {
    final q = OutboxQueue();
    await q.enqueue(op(opId: 'a'));
    await q.markInflight('a');
    final pendingNow = await q.pending();
    expect(pendingNow[0].status, OutboxOpStatus.inflight);
    await q.markPending('a', lastError: 'boom', attempts: 1);
    final later = await q.pending();
    expect(later[0].status, OutboxOpStatus.pending);
    expect(later[0].attempts, 1);
    expect(later[0].lastError, 'boom');
  });

  test('remove drops the op', () async {
    final q = OutboxQueue();
    await q.enqueue(op(opId: 'a'));
    await q.remove('a');
    expect((await q.pending()).isEmpty, true);
  });

  test('onBoot resets inflight → pending', () async {
    final q = OutboxQueue();
    await q.enqueue(op(opId: 'a', status: OutboxOpStatus.inflight));
    await q.onBoot();
    final list = await q.pending();
    expect(list[0].status, OutboxOpStatus.pending);
  });
}
