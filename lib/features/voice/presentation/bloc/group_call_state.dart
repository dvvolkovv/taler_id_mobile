import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/group_call.dart';

part 'group_call_state.freezed.dart';

@freezed
sealed class GroupCallState with _$GroupCallState {
  const factory GroupCallState.idle() = Idle;
  const factory GroupCallState.creating() = Creating;
  const factory GroupCallState.inLobby({
    required GroupCall groupCall,
    required String livekitToken,
    required String livekitWsUrl,
  }) = InLobby;
  const factory GroupCallState.inActive({
    required GroupCall groupCall,
    required String livekitToken,
    required String livekitWsUrl,
    @Default(false) bool muteRequestedByHost,
  }) = InActive;
  const factory GroupCallState.ended(String reason) = Ended;
  const factory GroupCallState.error(String message) = ErrorState;
}
