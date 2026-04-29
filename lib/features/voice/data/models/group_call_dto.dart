import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_call_dto.freezed.dart';
part 'group_call_dto.g.dart';

enum GroupCallStatusDto {
  @JsonValue('LOBBY')
  lobby,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('ENDED')
  ended,
}

enum GroupCallInviteStatusDto {
  @JsonValue('CALLING')
  calling,
  @JsonValue('JOINED')
  joined,
  @JsonValue('DECLINED')
  declined,
  @JsonValue('TIMEOUT')
  timeout,
  @JsonValue('LEFT')
  left,
}

@freezed
class ProfileSummaryDto with _$ProfileSummaryDto {
  const factory ProfileSummaryDto({
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) = _ProfileSummaryDto;

  factory ProfileSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileSummaryDtoFromJson(json);
}

@freezed
class UserSummaryDto with _$UserSummaryDto {
  const factory UserSummaryDto({
    required String id,
    ProfileSummaryDto? profile,
  }) = _UserSummaryDto;

  factory UserSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$UserSummaryDtoFromJson(json);
}

@freezed
class GroupCallInviteDto with _$GroupCallInviteDto {
  const factory GroupCallInviteDto({
    required String id,
    required String groupCallId,
    required String userId,
    required GroupCallInviteStatusDto status,
    required DateTime invitedAt,
    DateTime? respondedAt,
    DateTime? joinedAt,
    DateTime? leftAt,
    UserSummaryDto? user,
  }) = _GroupCallInviteDto;

  factory GroupCallInviteDto.fromJson(Map<String, dynamic> json) =>
      _$GroupCallInviteDtoFromJson(json);
}

@freezed
class GroupCallDto with _$GroupCallDto {
  const factory GroupCallDto({
    required String id,
    required String livekitRoomName,
    required String hostUserId,
    required GroupCallStatusDto status,
    required DateTime startedAt,
    DateTime? endedAt,
    String? endedReason,
    UserSummaryDto? host,
    @Default([]) List<GroupCallInviteDto> invites,
  }) = _GroupCallDto;

  factory GroupCallDto.fromJson(Map<String, dynamic> json) =>
      _$GroupCallDtoFromJson(json);
}

@freezed
class CreateGroupCallResponseDto with _$CreateGroupCallResponseDto {
  const factory CreateGroupCallResponseDto({
    required GroupCallDto groupCall,
    required String livekitToken,
    required String livekitWsUrl,
  }) = _CreateGroupCallResponseDto;

  factory CreateGroupCallResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupCallResponseDtoFromJson(json);
}

@freezed
class JoinGroupCallResponseDto with _$JoinGroupCallResponseDto {
  const factory JoinGroupCallResponseDto({
    required String livekitToken,
    required String livekitWsUrl,
  }) = _JoinGroupCallResponseDto;

  factory JoinGroupCallResponseDto.fromJson(Map<String, dynamic> json) =>
      _$JoinGroupCallResponseDtoFromJson(json);
}

@freezed
class ActiveGroupCallsResponseDto with _$ActiveGroupCallsResponseDto {
  const factory ActiveGroupCallsResponseDto({
    @Default([]) List<GroupCallDto> calls,
  }) = _ActiveGroupCallsResponseDto;

  factory ActiveGroupCallsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ActiveGroupCallsResponseDtoFromJson(json);
}

@freezed
class GetGroupCallResponseDto with _$GetGroupCallResponseDto {
  const factory GetGroupCallResponseDto({
    required GroupCallDto groupCall,
  }) = _GetGroupCallResponseDto;

  factory GetGroupCallResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetGroupCallResponseDtoFromJson(json);
}
