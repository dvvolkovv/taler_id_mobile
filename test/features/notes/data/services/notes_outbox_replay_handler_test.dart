import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_handler.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:taler_id_mobile/features/notes/data/services/notes_outbox_replay_handler.dart';

class _MockRemote extends Mock implements NotesRemoteDataSource {}

OutboxOp _op({
  OutboxOpKind op = OutboxOpKind.create,
  Map<String, dynamic>? payload,
  DateTime? expectedUpdatedAt,
}) =>
    OutboxOp(
      opId: 'op-1',
      feature: 'notes',
      op: op,
      entityId: 'n-1',
      payload: payload,
      expectedUpdatedAt: expectedUpdatedAt,
      createdAt: DateTime.now(),
    );

void main() {
  late _MockRemote remote;
  late NotesOutboxReplayHandler handler;

  setUp(() {
    remote = _MockRemote();
    handler = NotesOutboxReplayHandler(remote: remote);
  });

  test('create success → OutboxReplaySuccess', () async {
    when(() => remote.create(id: 'n-1', title: 't', content: 'c', source: 'MANUAL'))
        .thenAnswer((_) async => {'id': 'n-1', 'title': 't'});
    final res = await handler.replay(
      _op(payload: {'title': 't', 'content': 'c', 'source': 'MANUAL'}),
    );
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('update conflict → OutboxReplayConflict with serverData', () async {
    when(() => remote.update(
          'n-1',
          title: 't',
          content: null,
          expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
        )).thenThrow(NoteConflictException({'title': 'srv'}));
    final res = await handler.replay(
      _op(
        op: OutboxOpKind.update,
        payload: {'title': 't'},
        expectedUpdatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
      ),
    );
    expect(res, isA<OutboxReplayConflict>());
    expect((res as OutboxReplayConflict).serverData, {'title': 'srv'});
  });

  test('delete 404 → success (idempotent via datasource)', () async {
    when(() => remote.delete('n-1')).thenAnswer((_) async {});
    final res = await handler.replay(_op(op: OutboxOpKind.delete));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('unknown error → retry', () async {
    when(() => remote.create(id: 'n-1', title: 't', content: 'c', source: 'MANUAL'))
        .thenThrow(Exception('network'));
    final res = await handler.replay(
      _op(payload: {'title': 't', 'content': 'c', 'source': 'MANUAL'}),
    );
    expect(res, isA<OutboxReplayRetry>());
  });
}
