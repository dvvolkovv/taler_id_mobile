import 'package:freezed_annotation/freezed_annotation.dart';

import 'group_call_invite.dart';

part 'group_call.freezed.dart';

enum GroupCallStatus { lobby, active, ended }

@freezed
class GroupCall with _$GroupCall {
  const factory GroupCall({
    required String id,
    required String livekitRoomName,
    required String hostUserId,
    required String hostDisplayName,
    String? hostAvatarUrl,
    required GroupCallStatus status,
    required DateTime startedAt,
    @Default([]) List<GroupCallInvite> invites,
  }) = _GroupCall;
}
