import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_handler.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:taler_id_mobile/features/calendar/data/services/calendar_outbox_replay_handler.dart';

class _MockRemote extends Mock implements CalendarRemoteDataSource {}

OutboxOp _op({
  OutboxOpKind op = OutboxOpKind.create,
  Map<String, dynamic>? payload,
  DateTime? expectedUpdatedAt,
}) =>
    OutboxOp(
      opId: 'op-1',
      feature: 'calendar',
      op: op,
      entityId: 'e-1',
      payload: payload,
      expectedUpdatedAt: expectedUpdatedAt,
      createdAt: DateTime.now(),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late _MockRemote remote;
  late CalendarOutboxReplayHandler handler;

  setUp(() {
    remote = _MockRemote();
    handler = CalendarOutboxReplayHandler(remote: remote);
  });

  test('create success → OutboxReplaySuccess', () async {
    when(() => remote.create(any(), id: 'e-1'))
        .thenAnswer((_) async => {'id': 'e-1', 'title': 't'});
    final res = await handler.replay(
      _op(payload: {'title': 't', 'type': 'EVENT', 'startAt': '2026-05-14T10:00:00Z'}),
    );
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('update conflict → OutboxReplayConflict with serverData', () async {
    when(() => remote.update('e-1', any(), expectedUpdatedAt: any(named: 'expectedUpdatedAt')))
        .thenThrow(CalendarConflictException({'id': 'e-1', 'title': 'srv'}));
    final res = await handler.replay(_op(
      op: OutboxOpKind.update,
      payload: {'title': 't'},
      expectedUpdatedAt: DateTime.parse('2026-05-14T10:00:00Z'),
    ));
    expect(res, isA<OutboxReplayConflict>());
    expect((res as OutboxReplayConflict).serverData['title'], 'srv');
  });

  test('delete 404 → success (idempotent via datasource)', () async {
    when(() => remote.delete('e-1')).thenAnswer((_) async {});
    final res = await handler.replay(_op(op: OutboxOpKind.delete));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('unknown error → retry', () async {
    when(() => remote.create(any(), id: 'e-1')).thenThrow(Exception('network'));
    final res = await handler.replay(
      _op(payload: {'title': 't', 'type': 'EVENT', 'startAt': '2026-05-14T10:00:00Z'}),
    );
    expect(res, isA<OutboxReplayRetry>());
  });
}
