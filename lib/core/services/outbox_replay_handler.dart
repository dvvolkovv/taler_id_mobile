import '../storage/outbox_op.dart';

abstract class OutboxReplayHandler {
  String get feature;
  Future<OutboxReplayResult> replay(OutboxOp op);
}

sealed class OutboxReplayResult {
  const OutboxReplayResult();
  factory OutboxReplayResult.success({Map<String, dynamic>? serverEntity}) =
      OutboxReplaySuccess;
  factory OutboxReplayResult.retry({required String error}) = OutboxReplayRetry;
  factory OutboxReplayResult.conflict({required Map<String, dynamic> serverData}) =
      OutboxReplayConflict;
  factory OutboxReplayResult.dead({required String error}) = OutboxReplayDead;
}

class OutboxReplaySuccess extends OutboxReplayResult {
  final Map<String, dynamic>? serverEntity;
  const OutboxReplaySuccess({this.serverEntity});
}

class OutboxReplayRetry extends OutboxReplayResult {
  final String error;
  const OutboxReplayRetry({required this.error});
}

class OutboxReplayConflict extends OutboxReplayResult {
  final Map<String, dynamic> serverData;
  const OutboxReplayConflict({required this.serverData});
}

class OutboxReplayDead extends OutboxReplayResult {
  final String error;
  const OutboxReplayDead({required this.error});
}
