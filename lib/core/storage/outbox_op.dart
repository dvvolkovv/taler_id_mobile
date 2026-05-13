import 'package:freezed_annotation/freezed_annotation.dart';

part 'outbox_op.freezed.dart';
part 'outbox_op.g.dart';

enum OutboxOpKind { create, update, delete }

enum OutboxOpStatus { pending, inflight, failedConflict, failedDead }

@freezed
class OutboxOp with _$OutboxOp {
  const factory OutboxOp({
    required String opId,
    required String feature,
    required OutboxOpKind op,
    required String entityId,
    Map<String, dynamic>? payload,
    DateTime? expectedUpdatedAt,
    @Default(0) int attempts,
    @Default(OutboxOpStatus.pending) OutboxOpStatus status,
    required DateTime createdAt,
    DateTime? lastAttemptAt,
    String? lastError,
    Map<String, dynamic>? serverData,
  }) = _OutboxOp;

  factory OutboxOp.fromJson(Map<String, dynamic> json) => _$OutboxOpFromJson(json);
}
