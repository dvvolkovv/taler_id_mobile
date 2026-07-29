import 'package:dio/dio.dart';
import '../../../../core/services/outbox_replay_handler.dart';
import '../../../../core/storage/outbox_op.dart';
import '../datasources/notes_local_datasource.dart';
import '../datasources/notes_remote_datasource.dart';

class NotesOutboxReplayHandler implements OutboxReplayHandler {
  final NotesRemoteDataSource _remote;
  final NotesLocalDataSource _local;
  NotesOutboxReplayHandler({
    required NotesRemoteDataSource remote,
    required NotesLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  String get feature => 'notes';

  /// After a create/update lands on the server, clear the local `localPending`
  /// flag so the note stops showing as unsynced. The generic replay service
  /// only removes the outbox op on success; without this the flag lingered
  /// until the next full refresh() (a GET /notes reconcile), so a freshly
  /// created note kept its "syncing" indicator even though it was already
  /// persisted server-side. We keep the local content and only adopt the
  /// server's updatedAt (for the next update's optimistic-concurrency check).
  Future<void> _clearPending(String id, Map<String, dynamic>? server) async {
    final existing = await _local.getById(id);
    if (existing == null || !existing.localPending) return;
    final serverUpdatedAt = DateTime.tryParse(
      (server?['updatedAt'] as String?) ?? '',
    );
    await _local.upsert(existing.copyWith(
      localPending: false,
      updatedAt: serverUpdatedAt ?? existing.updatedAt,
    ));
  }

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
          await _clearPending(op.entityId, serverEntity);
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.update:
          final p = op.payload ?? {};
          final serverEntity = await _remote.update(
            op.entityId,
            title: p['title'] as String?,
            content: p['content'] as String?,
            expectedUpdatedAt: op.expectedUpdatedAt,
          );
          await _clearPending(op.entityId, serverEntity);
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
