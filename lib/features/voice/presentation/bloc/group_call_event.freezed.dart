// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_call_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$GroupCallEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupCallEventCopyWith<$Res> {
  factory $GroupCallEventCopyWith(
          GroupCallEvent value, $Res Function(GroupCallEvent) then) =
      _$GroupCallEventCopyWithImpl<$Res, GroupCallEvent>;
}

/// @nodoc
class _$GroupCallEventCopyWithImpl<$Res, $Val extends GroupCallEvent>
    implements $GroupCallEventCopyWith<$Res> {
  _$GroupCallEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$CreateCallImplCopyWith<$Res> {
  factory _$$CreateCallImplCopyWith(
          _$CreateCallImpl value, $Res Function(_$CreateCallImpl) then) =
      __$$CreateCallImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<String> inviteeIds});
}

/// @nodoc
class __$$CreateCallImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$CreateCallImpl>
    implements _$$CreateCallImplCopyWith<$Res> {
  __$$CreateCallImplCopyWithImpl(
      _$CreateCallImpl _value, $Res Function(_$CreateCallImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? inviteeIds = null,
  }) {
    return _then(_$CreateCallImpl(
      null == inviteeIds
          ? _value._inviteeIds
          : inviteeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$CreateCallImpl implements CreateCall {
  const _$CreateCallImpl(final List<String> inviteeIds)
      : _inviteeIds = inviteeIds;

  final List<String> _inviteeIds;
  @override
  List<String> get inviteeIds {
    if (_inviteeIds is EqualUnmodifiableListView) return _inviteeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_inviteeIds);
  }

  @override
  String toString() {
    return 'GroupCallEvent.createCall(inviteeIds: $inviteeIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateCallImpl &&
            const DeepCollectionEquality()
                .equals(other._inviteeIds, _inviteeIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_inviteeIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateCallImplCopyWith<_$CreateCallImpl> get copyWith =>
      __$$CreateCallImplCopyWithImpl<_$CreateCallImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return createCall(inviteeIds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return createCall?.call(inviteeIds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (createCall != null) {
      return createCall(inviteeIds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return createCall(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return createCall?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (createCall != null) {
      return createCall(this);
    }
    return orElse();
  }
}

abstract class CreateCall implements GroupCallEvent {
  const factory CreateCall(final List<String> inviteeIds) = _$CreateCallImpl;

  List<String> get inviteeIds;
  @JsonKey(ignore: true)
  _$$CreateCallImplCopyWith<_$CreateCallImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$JoinCallImplCopyWith<$Res> {
  factory _$$JoinCallImplCopyWith(
          _$JoinCallImpl value, $Res Function(_$JoinCallImpl) then) =
      __$$JoinCallImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String callId});
}

/// @nodoc
class __$$JoinCallImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$JoinCallImpl>
    implements _$$JoinCallImplCopyWith<$Res> {
  __$$JoinCallImplCopyWithImpl(
      _$JoinCallImpl _value, $Res Function(_$JoinCallImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? callId = null,
  }) {
    return _then(_$JoinCallImpl(
      null == callId
          ? _value.callId
          : callId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$JoinCallImpl implements JoinCall {
  const _$JoinCallImpl(this.callId);

  @override
  final String callId;

  @override
  String toString() {
    return 'GroupCallEvent.joinCall(callId: $callId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JoinCallImpl &&
            (identical(other.callId, callId) || other.callId == callId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, callId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$JoinCallImplCopyWith<_$JoinCallImpl> get copyWith =>
      __$$JoinCallImplCopyWithImpl<_$JoinCallImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return joinCall(callId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return joinCall?.call(callId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (joinCall != null) {
      return joinCall(callId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return joinCall(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return joinCall?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (joinCall != null) {
      return joinCall(this);
    }
    return orElse();
  }
}

abstract class JoinCall implements GroupCallEvent {
  const factory JoinCall(final String callId) = _$JoinCallImpl;

  String get callId;
  @JsonKey(ignore: true)
  _$$JoinCallImplCopyWith<_$JoinCallImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeclineCallImplCopyWith<$Res> {
  factory _$$DeclineCallImplCopyWith(
          _$DeclineCallImpl value, $Res Function(_$DeclineCallImpl) then) =
      __$$DeclineCallImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String callId});
}

/// @nodoc
class __$$DeclineCallImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$DeclineCallImpl>
    implements _$$DeclineCallImplCopyWith<$Res> {
  __$$DeclineCallImplCopyWithImpl(
      _$DeclineCallImpl _value, $Res Function(_$DeclineCallImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? callId = null,
  }) {
    return _then(_$DeclineCallImpl(
      null == callId
          ? _value.callId
          : callId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DeclineCallImpl implements DeclineCall {
  const _$DeclineCallImpl(this.callId);

  @override
  final String callId;

  @override
  String toString() {
    return 'GroupCallEvent.declineCall(callId: $callId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeclineCallImpl &&
            (identical(other.callId, callId) || other.callId == callId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, callId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeclineCallImplCopyWith<_$DeclineCallImpl> get copyWith =>
      __$$DeclineCallImplCopyWithImpl<_$DeclineCallImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return declineCall(callId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return declineCall?.call(callId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (declineCall != null) {
      return declineCall(callId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return declineCall(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return declineCall?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (declineCall != null) {
      return declineCall(this);
    }
    return orElse();
  }
}

abstract class DeclineCall implements GroupCallEvent {
  const factory DeclineCall(final String callId) = _$DeclineCallImpl;

  String get callId;
  @JsonKey(ignore: true)
  _$$DeclineCallImplCopyWith<_$DeclineCallImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LeaveCallImplCopyWith<$Res> {
  factory _$$LeaveCallImplCopyWith(
          _$LeaveCallImpl value, $Res Function(_$LeaveCallImpl) then) =
      __$$LeaveCallImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String callId});
}

/// @nodoc
class __$$LeaveCallImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$LeaveCallImpl>
    implements _$$LeaveCallImplCopyWith<$Res> {
  __$$LeaveCallImplCopyWithImpl(
      _$LeaveCallImpl _value, $Res Function(_$LeaveCallImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? callId = null,
  }) {
    return _then(_$LeaveCallImpl(
      null == callId
          ? _value.callId
          : callId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$LeaveCallImpl implements LeaveCall {
  const _$LeaveCallImpl(this.callId);

  @override
  final String callId;

  @override
  String toString() {
    return 'GroupCallEvent.leaveCall(callId: $callId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaveCallImpl &&
            (identical(other.callId, callId) || other.callId == callId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, callId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaveCallImplCopyWith<_$LeaveCallImpl> get copyWith =>
      __$$LeaveCallImplCopyWithImpl<_$LeaveCallImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return leaveCall(callId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return leaveCall?.call(callId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (leaveCall != null) {
      return leaveCall(callId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return leaveCall(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return leaveCall?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (leaveCall != null) {
      return leaveCall(this);
    }
    return orElse();
  }
}

abstract class LeaveCall implements GroupCallEvent {
  const factory LeaveCall(final String callId) = _$LeaveCallImpl;

  String get callId;
  @JsonKey(ignore: true)
  _$$LeaveCallImplCopyWith<_$LeaveCallImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InviteMoreImplCopyWith<$Res> {
  factory _$$InviteMoreImplCopyWith(
          _$InviteMoreImpl value, $Res Function(_$InviteMoreImpl) then) =
      __$$InviteMoreImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String callId, List<String> userIds});
}

/// @nodoc
class __$$InviteMoreImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$InviteMoreImpl>
    implements _$$InviteMoreImplCopyWith<$Res> {
  __$$InviteMoreImplCopyWithImpl(
      _$InviteMoreImpl _value, $Res Function(_$InviteMoreImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? callId = null,
    Object? userIds = null,
  }) {
    return _then(_$InviteMoreImpl(
      null == callId
          ? _value.callId
          : callId // ignore: cast_nullable_to_non_nullable
              as String,
      null == userIds
          ? _value._userIds
          : userIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$InviteMoreImpl implements InviteMore {
  const _$InviteMoreImpl(this.callId, final List<String> userIds)
      : _userIds = userIds;

  @override
  final String callId;
  final List<String> _userIds;
  @override
  List<String> get userIds {
    if (_userIds is EqualUnmodifiableListView) return _userIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_userIds);
  }

  @override
  String toString() {
    return 'GroupCallEvent.inviteMore(callId: $callId, userIds: $userIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InviteMoreImpl &&
            (identical(other.callId, callId) || other.callId == callId) &&
            const DeepCollectionEquality().equals(other._userIds, _userIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, callId, const DeepCollectionEquality().hash(_userIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InviteMoreImplCopyWith<_$InviteMoreImpl> get copyWith =>
      __$$InviteMoreImplCopyWithImpl<_$InviteMoreImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return inviteMore(callId, userIds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return inviteMore?.call(callId, userIds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (inviteMore != null) {
      return inviteMore(callId, userIds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return inviteMore(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return inviteMore?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (inviteMore != null) {
      return inviteMore(this);
    }
    return orElse();
  }
}

abstract class InviteMore implements GroupCallEvent {
  const factory InviteMore(final String callId, final List<String> userIds) =
      _$InviteMoreImpl;

  String get callId;
  List<String> get userIds;
  @JsonKey(ignore: true)
  _$$InviteMoreImplCopyWith<_$InviteMoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$KickImplCopyWith<$Res> {
  factory _$$KickImplCopyWith(
          _$KickImpl value, $Res Function(_$KickImpl) then) =
      __$$KickImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String callId, String userId});
}

/// @nodoc
class __$$KickImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$KickImpl>
    implements _$$KickImplCopyWith<$Res> {
  __$$KickImplCopyWithImpl(_$KickImpl _value, $Res Function(_$KickImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? callId = null,
    Object? userId = null,
  }) {
    return _then(_$KickImpl(
      null == callId
          ? _value.callId
          : callId // ignore: cast_nullable_to_non_nullable
              as String,
      null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$KickImpl implements Kick {
  const _$KickImpl(this.callId, this.userId);

  @override
  final String callId;
  @override
  final String userId;

  @override
  String toString() {
    return 'GroupCallEvent.kick(callId: $callId, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KickImpl &&
            (identical(other.callId, callId) || other.callId == callId) &&
            (identical(other.userId, userId) || other.userId == userId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, callId, userId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$KickImplCopyWith<_$KickImpl> get copyWith =>
      __$$KickImplCopyWithImpl<_$KickImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return kick(callId, userId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return kick?.call(callId, userId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (kick != null) {
      return kick(callId, userId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return kick(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return kick?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (kick != null) {
      return kick(this);
    }
    return orElse();
  }
}

abstract class Kick implements GroupCallEvent {
  const factory Kick(final String callId, final String userId) = _$KickImpl;

  String get callId;
  String get userId;
  @JsonKey(ignore: true)
  _$$KickImplCopyWith<_$KickImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MuteAllImplCopyWith<$Res> {
  factory _$$MuteAllImplCopyWith(
          _$MuteAllImpl value, $Res Function(_$MuteAllImpl) then) =
      __$$MuteAllImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String callId});
}

/// @nodoc
class __$$MuteAllImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$MuteAllImpl>
    implements _$$MuteAllImplCopyWith<$Res> {
  __$$MuteAllImplCopyWithImpl(
      _$MuteAllImpl _value, $Res Function(_$MuteAllImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? callId = null,
  }) {
    return _then(_$MuteAllImpl(
      null == callId
          ? _value.callId
          : callId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MuteAllImpl implements MuteAll {
  const _$MuteAllImpl(this.callId);

  @override
  final String callId;

  @override
  String toString() {
    return 'GroupCallEvent.muteAll(callId: $callId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MuteAllImpl &&
            (identical(other.callId, callId) || other.callId == callId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, callId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MuteAllImplCopyWith<_$MuteAllImpl> get copyWith =>
      __$$MuteAllImplCopyWithImpl<_$MuteAllImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return muteAll(callId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return muteAll?.call(callId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (muteAll != null) {
      return muteAll(callId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return muteAll(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return muteAll?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (muteAll != null) {
      return muteAll(this);
    }
    return orElse();
  }
}

abstract class MuteAll implements GroupCallEvent {
  const factory MuteAll(final String callId) = _$MuteAllImpl;

  String get callId;
  @JsonKey(ignore: true)
  _$$MuteAllImplCopyWith<_$MuteAllImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EndCallImplCopyWith<$Res> {
  factory _$$EndCallImplCopyWith(
          _$EndCallImpl value, $Res Function(_$EndCallImpl) then) =
      __$$EndCallImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String callId});
}

/// @nodoc
class __$$EndCallImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$EndCallImpl>
    implements _$$EndCallImplCopyWith<$Res> {
  __$$EndCallImplCopyWithImpl(
      _$EndCallImpl _value, $Res Function(_$EndCallImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? callId = null,
  }) {
    return _then(_$EndCallImpl(
      null == callId
          ? _value.callId
          : callId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$EndCallImpl implements EndCall {
  const _$EndCallImpl(this.callId);

  @override
  final String callId;

  @override
  String toString() {
    return 'GroupCallEvent.endCall(callId: $callId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EndCallImpl &&
            (identical(other.callId, callId) || other.callId == callId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, callId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EndCallImplCopyWith<_$EndCallImpl> get copyWith =>
      __$$EndCallImplCopyWithImpl<_$EndCallImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return endCall(callId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return endCall?.call(callId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (endCall != null) {
      return endCall(callId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return endCall(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return endCall?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (endCall != null) {
      return endCall(this);
    }
    return orElse();
  }
}

abstract class EndCall implements GroupCallEvent {
  const factory EndCall(final String callId) = _$EndCallImpl;

  String get callId;
  @JsonKey(ignore: true)
  _$$EndCallImplCopyWith<_$EndCallImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StatusUpdatedImplCopyWith<$Res> {
  factory _$$StatusUpdatedImplCopyWith(
          _$StatusUpdatedImpl value, $Res Function(_$StatusUpdatedImpl) then) =
      __$$StatusUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> payload});
}

/// @nodoc
class __$$StatusUpdatedImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$StatusUpdatedImpl>
    implements _$$StatusUpdatedImplCopyWith<$Res> {
  __$$StatusUpdatedImplCopyWithImpl(
      _$StatusUpdatedImpl _value, $Res Function(_$StatusUpdatedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payload = null,
  }) {
    return _then(_$StatusUpdatedImpl(
      null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

class _$StatusUpdatedImpl implements StatusUpdated {
  const _$StatusUpdatedImpl(final Map<String, dynamic> payload)
      : _payload = payload;

  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  String toString() {
    return 'GroupCallEvent.statusUpdated(payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatusUpdatedImpl &&
            const DeepCollectionEquality().equals(other._payload, _payload));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_payload));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StatusUpdatedImplCopyWith<_$StatusUpdatedImpl> get copyWith =>
      __$$StatusUpdatedImplCopyWithImpl<_$StatusUpdatedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return statusUpdated(payload);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return statusUpdated?.call(payload);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (statusUpdated != null) {
      return statusUpdated(payload);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return statusUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return statusUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (statusUpdated != null) {
      return statusUpdated(this);
    }
    return orElse();
  }
}

abstract class StatusUpdated implements GroupCallEvent {
  const factory StatusUpdated(final Map<String, dynamic> payload) =
      _$StatusUpdatedImpl;

  Map<String, dynamic> get payload;
  @JsonKey(ignore: true)
  _$$StatusUpdatedImplCopyWith<_$StatusUpdatedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$KickedImplCopyWith<$Res> {
  factory _$$KickedImplCopyWith(
          _$KickedImpl value, $Res Function(_$KickedImpl) then) =
      __$$KickedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> payload});
}

/// @nodoc
class __$$KickedImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$KickedImpl>
    implements _$$KickedImplCopyWith<$Res> {
  __$$KickedImplCopyWithImpl(
      _$KickedImpl _value, $Res Function(_$KickedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payload = null,
  }) {
    return _then(_$KickedImpl(
      null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

class _$KickedImpl implements Kicked {
  const _$KickedImpl(final Map<String, dynamic> payload) : _payload = payload;

  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  String toString() {
    return 'GroupCallEvent.kicked(payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KickedImpl &&
            const DeepCollectionEquality().equals(other._payload, _payload));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_payload));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$KickedImplCopyWith<_$KickedImpl> get copyWith =>
      __$$KickedImplCopyWithImpl<_$KickedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return kicked(payload);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return kicked?.call(payload);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (kicked != null) {
      return kicked(payload);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return kicked(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return kicked?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (kicked != null) {
      return kicked(this);
    }
    return orElse();
  }
}

abstract class Kicked implements GroupCallEvent {
  const factory Kicked(final Map<String, dynamic> payload) = _$KickedImpl;

  Map<String, dynamic> get payload;
  @JsonKey(ignore: true)
  _$$KickedImplCopyWith<_$KickedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MuteRequestedImplCopyWith<$Res> {
  factory _$$MuteRequestedImplCopyWith(
          _$MuteRequestedImpl value, $Res Function(_$MuteRequestedImpl) then) =
      __$$MuteRequestedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> payload});
}

/// @nodoc
class __$$MuteRequestedImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$MuteRequestedImpl>
    implements _$$MuteRequestedImplCopyWith<$Res> {
  __$$MuteRequestedImplCopyWithImpl(
      _$MuteRequestedImpl _value, $Res Function(_$MuteRequestedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payload = null,
  }) {
    return _then(_$MuteRequestedImpl(
      null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

class _$MuteRequestedImpl implements MuteRequested {
  const _$MuteRequestedImpl(final Map<String, dynamic> payload)
      : _payload = payload;

  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  String toString() {
    return 'GroupCallEvent.muteRequested(payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MuteRequestedImpl &&
            const DeepCollectionEquality().equals(other._payload, _payload));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_payload));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MuteRequestedImplCopyWith<_$MuteRequestedImpl> get copyWith =>
      __$$MuteRequestedImplCopyWithImpl<_$MuteRequestedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return muteRequested(payload);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return muteRequested?.call(payload);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (muteRequested != null) {
      return muteRequested(payload);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return muteRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return muteRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (muteRequested != null) {
      return muteRequested(this);
    }
    return orElse();
  }
}

abstract class MuteRequested implements GroupCallEvent {
  const factory MuteRequested(final Map<String, dynamic> payload) =
      _$MuteRequestedImpl;

  Map<String, dynamic> get payload;
  @JsonKey(ignore: true)
  _$$MuteRequestedImplCopyWith<_$MuteRequestedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$HostChangedImplCopyWith<$Res> {
  factory _$$HostChangedImplCopyWith(
          _$HostChangedImpl value, $Res Function(_$HostChangedImpl) then) =
      __$$HostChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> payload});
}

/// @nodoc
class __$$HostChangedImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$HostChangedImpl>
    implements _$$HostChangedImplCopyWith<$Res> {
  __$$HostChangedImplCopyWithImpl(
      _$HostChangedImpl _value, $Res Function(_$HostChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payload = null,
  }) {
    return _then(_$HostChangedImpl(
      null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

class _$HostChangedImpl implements HostChanged {
  const _$HostChangedImpl(final Map<String, dynamic> payload)
      : _payload = payload;

  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  String toString() {
    return 'GroupCallEvent.hostChanged(payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HostChangedImpl &&
            const DeepCollectionEquality().equals(other._payload, _payload));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_payload));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HostChangedImplCopyWith<_$HostChangedImpl> get copyWith =>
      __$$HostChangedImplCopyWithImpl<_$HostChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return hostChanged(payload);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return hostChanged?.call(payload);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (hostChanged != null) {
      return hostChanged(payload);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return hostChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return hostChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (hostChanged != null) {
      return hostChanged(this);
    }
    return orElse();
  }
}

abstract class HostChanged implements GroupCallEvent {
  const factory HostChanged(final Map<String, dynamic> payload) =
      _$HostChangedImpl;

  Map<String, dynamic> get payload;
  @JsonKey(ignore: true)
  _$$HostChangedImplCopyWith<_$HostChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EndedImplCopyWith<$Res> {
  factory _$$EndedImplCopyWith(
          _$EndedImpl value, $Res Function(_$EndedImpl) then) =
      __$$EndedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> payload});
}

/// @nodoc
class __$$EndedImplCopyWithImpl<$Res>
    extends _$GroupCallEventCopyWithImpl<$Res, _$EndedImpl>
    implements _$$EndedImplCopyWith<$Res> {
  __$$EndedImplCopyWithImpl(
      _$EndedImpl _value, $Res Function(_$EndedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payload = null,
  }) {
    return _then(_$EndedImpl(
      null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

class _$EndedImpl implements Ended {
  const _$EndedImpl(final Map<String, dynamic> payload) : _payload = payload;

  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  String toString() {
    return 'GroupCallEvent.ended(payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EndedImpl &&
            const DeepCollectionEquality().equals(other._payload, _payload));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_payload));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EndedImplCopyWith<_$EndedImpl> get copyWith =>
      __$$EndedImplCopyWithImpl<_$EndedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> inviteeIds) createCall,
    required TResult Function(String callId) joinCall,
    required TResult Function(String callId) declineCall,
    required TResult Function(String callId) leaveCall,
    required TResult Function(String callId, List<String> userIds) inviteMore,
    required TResult Function(String callId, String userId) kick,
    required TResult Function(String callId) muteAll,
    required TResult Function(String callId) endCall,
    required TResult Function(Map<String, dynamic> payload) statusUpdated,
    required TResult Function(Map<String, dynamic> payload) kicked,
    required TResult Function(Map<String, dynamic> payload) muteRequested,
    required TResult Function(Map<String, dynamic> payload) hostChanged,
    required TResult Function(Map<String, dynamic> payload) ended,
  }) {
    return ended(payload);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> inviteeIds)? createCall,
    TResult? Function(String callId)? joinCall,
    TResult? Function(String callId)? declineCall,
    TResult? Function(String callId)? leaveCall,
    TResult? Function(String callId, List<String> userIds)? inviteMore,
    TResult? Function(String callId, String userId)? kick,
    TResult? Function(String callId)? muteAll,
    TResult? Function(String callId)? endCall,
    TResult? Function(Map<String, dynamic> payload)? statusUpdated,
    TResult? Function(Map<String, dynamic> payload)? kicked,
    TResult? Function(Map<String, dynamic> payload)? muteRequested,
    TResult? Function(Map<String, dynamic> payload)? hostChanged,
    TResult? Function(Map<String, dynamic> payload)? ended,
  }) {
    return ended?.call(payload);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> inviteeIds)? createCall,
    TResult Function(String callId)? joinCall,
    TResult Function(String callId)? declineCall,
    TResult Function(String callId)? leaveCall,
    TResult Function(String callId, List<String> userIds)? inviteMore,
    TResult Function(String callId, String userId)? kick,
    TResult Function(String callId)? muteAll,
    TResult Function(String callId)? endCall,
    TResult Function(Map<String, dynamic> payload)? statusUpdated,
    TResult Function(Map<String, dynamic> payload)? kicked,
    TResult Function(Map<String, dynamic> payload)? muteRequested,
    TResult Function(Map<String, dynamic> payload)? hostChanged,
    TResult Function(Map<String, dynamic> payload)? ended,
    required TResult orElse(),
  }) {
    if (ended != null) {
      return ended(payload);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CreateCall value) createCall,
    required TResult Function(JoinCall value) joinCall,
    required TResult Function(DeclineCall value) declineCall,
    required TResult Function(LeaveCall value) leaveCall,
    required TResult Function(InviteMore value) inviteMore,
    required TResult Function(Kick value) kick,
    required TResult Function(MuteAll value) muteAll,
    required TResult Function(EndCall value) endCall,
    required TResult Function(StatusUpdated value) statusUpdated,
    required TResult Function(Kicked value) kicked,
    required TResult Function(MuteRequested value) muteRequested,
    required TResult Function(HostChanged value) hostChanged,
    required TResult Function(Ended value) ended,
  }) {
    return ended(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CreateCall value)? createCall,
    TResult? Function(JoinCall value)? joinCall,
    TResult? Function(DeclineCall value)? declineCall,
    TResult? Function(LeaveCall value)? leaveCall,
    TResult? Function(InviteMore value)? inviteMore,
    TResult? Function(Kick value)? kick,
    TResult? Function(MuteAll value)? muteAll,
    TResult? Function(EndCall value)? endCall,
    TResult? Function(StatusUpdated value)? statusUpdated,
    TResult? Function(Kicked value)? kicked,
    TResult? Function(MuteRequested value)? muteRequested,
    TResult? Function(HostChanged value)? hostChanged,
    TResult? Function(Ended value)? ended,
  }) {
    return ended?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CreateCall value)? createCall,
    TResult Function(JoinCall value)? joinCall,
    TResult Function(DeclineCall value)? declineCall,
    TResult Function(LeaveCall value)? leaveCall,
    TResult Function(InviteMore value)? inviteMore,
    TResult Function(Kick value)? kick,
    TResult Function(MuteAll value)? muteAll,
    TResult Function(EndCall value)? endCall,
    TResult Function(StatusUpdated value)? statusUpdated,
    TResult Function(Kicked value)? kicked,
    TResult Function(MuteRequested value)? muteRequested,
    TResult Function(HostChanged value)? hostChanged,
    TResult Function(Ended value)? ended,
    required TResult orElse(),
  }) {
    if (ended != null) {
      return ended(this);
    }
    return orElse();
  }
}

abstract class Ended implements GroupCallEvent {
  const factory Ended(final Map<String, dynamic> payload) = _$EndedImpl;

  Map<String, dynamic> get payload;
  @JsonKey(ignore: true)
  _$$EndedImplCopyWith<_$EndedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
