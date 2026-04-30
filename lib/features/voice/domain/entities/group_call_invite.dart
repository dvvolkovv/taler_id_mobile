import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_call_invite.freezed.dart';

enum GroupCallInviteStatus { calling, joined, declined, timeout, left }

@freezed
class GroupCallInvite with _$GroupCallInvite {
  const factory GroupCallInvite({
    required String id,
    required String userId,
    required String displayName,
    String? avatarUrl,
    required GroupCallInviteStatus status,
    DateTime? joinedAt,
    DateTime? leftAt,
  }) = _GroupCallInvite;
}
