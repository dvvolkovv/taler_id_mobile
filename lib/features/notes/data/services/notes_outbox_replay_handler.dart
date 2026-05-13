import 'package:dio/dio.dart';
import '../../../../core/services/outbox_replay_handler.dart';
import '../../../../core/storage/outbox_op.dart';
import '../datasources/notes_remote_datasource.dart';

class NotesOutboxReplayHandler implements OutboxReplayHandler {
  final NotesRemoteDataSource _remote;
  NotesOutboxReplayHandler({required NotesRemoteDataSource remote}) : _remote = remote;

  @override
  String get feature => 'notes';

  @override
  Future<OutboxReplayResult> replay(OutboxOp op) async {
    try {
      switch (op.op) {
        case OutboxOpKind.create:
          final p = op.payload ?? {};
          final serverEntity = await _remote.create(
            id: op.entityId,
            title: p['title'] as String? ?? '',
            content: p['content'] as String? ?? '',
            source: p['source'] as String? ?? 'MANUAL',
          );
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.update:
          final p = op.payload ?? {};
          final serverEntity = await _remote.update(
            op.entityId,
            title: p['title'] as String?,
            content: p['content'] as String?,
            expectedUpdatedAt: op.expectedUpdatedAt,
          );
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.delete:
          await _remote.delete(op.entityId);
          return OutboxReplayResult.success();
      }
    } on NoteConflictException catch (e) {
      return OutboxReplayResult.conflict(serverData: e.currentNote);
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code >= 400 && code < 500 && code != 408 && code != 429) {
        return OutboxReplayResult.dead(error: 'HTTP $code: ${e.message}');
      }
      return OutboxReplayResult.retry(error: 'HTTP $code: ${e.message}');
    } catch (e) {
      return OutboxReplayResult.retry(error: e.toString());
    }
  }
}
