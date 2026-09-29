import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_handler.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/features/calendar/data/datasources/task_remote_datasource.dart';
import 'package:taler_id_mobile/features/calendar/data/services/task_outbox_replay_handler.dart';

class _MockRemote extends Mock implements TaskRemoteDataSource {}

OutboxOp _op({
  OutboxOpKind op = OutboxOpKind.delete,
  Map<String, dynamic>? payload,
}) =>
    OutboxOp(
      opId: 'op-1',
      feature: 'task',
      op: op,
      entityId: 't-1',
      payload: payload,
      createdAt: DateTime.now(),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late _MockRemote remote;
  late TaskOutboxReplayHandler handler;

  setUp(() {
    remote = _MockRemote();
    handler = TaskOutboxReplayHandler(remote: remote);
  });

  test('feature is task', () {
    expect(handler.feature, 'task');
  });

  test('create success → OutboxReplaySuccess (client id passed through)', () async {
    when(() => remote.create(any(), id: 't-1'))
        .thenAnswer((_) async => {'id': 't-1', 'title': 'МТС'});
    final res = await handler.replay(_op(op: OutboxOpKind.create, payload: {'title': 'МТС'}));
    expect(res, isA<OutboxReplaySuccess>());
    verify(() => remote.create(any(), id: 't-1')).called(1);
  });

  test('status update calls setStatus with occurrenceDate', () async {
    when(() => remote.setStatus('t-1', 'done', occurrenceDate: '2026-09-29'))
        .thenAnswer((_) async => {'id': 't-1', 'status': 'done'});
    final res = await handler.replay(_op(
      op: OutboxOpKind.update,
      payload: {'status': 'done', 'occurrenceDate': '2026-09-29'},
    ));
    expect(res, isA<OutboxReplaySuccess>());
    verify(() => remote.setStatus('t-1', 'done', occurrenceDate: '2026-09-29')).called(1);
  });

  test('delete success → OutboxReplaySuccess', () async {
    when(() => remote.delete('t-1')).thenAnswer((_) async {});
    final res = await handler.replay(_op(op: OutboxOpKind.delete));
    expect(res, isA<OutboxReplaySuccess>());
  });

  // The reported bug: a lost/failed delete must be retried, not dropped. The
  // outbox retries a transient failure and treats an already-gone task (404)
  // as done — so the ghost can never persist server-side.
  test('delete ApiException(404) → success (idempotent, no poison retry)', () async {
    when(() => remote.delete('t-1'))
        .thenThrow(const ApiException(statusCode: 404, message: 'Task not found'));
    final res = await handler.replay(_op(op: OutboxOpKind.delete));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('delete ApiException(500) → retry (transient, keep trying)', () async {
    when(() => remote.delete('t-1'))
        .thenThrow(const ApiException(statusCode: 500, message: 'server'));
    final res = await handler.replay(_op(op: OutboxOpKind.delete));
    expect(res, isA<OutboxReplayRetry>());
  });

  test('delete ApiException(401) → retry (token will refresh)', () async {
    when(() => remote.delete('t-1'))
        .thenThrow(const ApiException(statusCode: 401, message: 'expired'));
    final res = await handler.replay(_op(op: OutboxOpKind.delete));
    expect(res, isA<OutboxReplayRetry>());
  });

  test('delete unknown error → retry', () async {
    when(() => remote.delete('t-1')).thenThrow(Exception('network'));
    final res = await handler.replay(_op(op: OutboxOpKind.delete));
    expect(res, isA<OutboxReplayRetry>());
  });

  test('create ApiException(400) → dead (permanent client error)', () async {
    when(() => remote.create(any(), id: 't-1'))
        .thenThrow(const ApiException(statusCode: 400, message: 'bad'));
    final res = await handler.replay(_op(op: OutboxOpKind.create, payload: {'title': 'x'}));
    expect(res, isA<OutboxReplayDead>());
  });
}
