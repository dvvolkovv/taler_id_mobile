import 'package:dio/dio.dart';
import '../../../../core/services/outbox_replay_handler.dart';
import '../../../../core/storage/outbox_op.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';

class ContactsOutboxReplayHandler implements OutboxReplayHandler {
  final MessengerRemoteDataSource _remote;
  ContactsOutboxReplayHandler({required MessengerRemoteDataSource remote})
      : _remote = remote;

  @override
  String get feature => 'contacts';

  @override
  Future<OutboxReplayResult> replay(OutboxOp op) async {
    final action = (op.payload ?? const {})['action'] as String? ?? '';
    try {
      switch (action) {
        case 'accept':
          await _remote.acceptContactRequest(op.entityId);
          return OutboxReplayResult.success();
        case 'reject':
          await _remote.rejectContactRequest(op.entityId);
          return OutboxReplayResult.success();
        default:
          return OutboxReplayResult.dead(error: 'unknown contacts action: $action');
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      // 404 (request already gone) or 409 (already not PENDING) are treated as
      // success — local state is already at the target (or refresh will reconcile).
      if (code == 404 || code == 409) {
        return OutboxReplayResult.success();
      }
      if (code >= 400 && code < 500 && code != 408 && code != 429) {
        return OutboxReplayResult.dead(error: 'HTTP $code: ${e.message}');
      }
      return OutboxReplayResult.retry(error: 'HTTP $code: ${e.message}');
    } catch (e) {
      return OutboxReplayResult.retry(error: e.toString());
    }
  }
}
