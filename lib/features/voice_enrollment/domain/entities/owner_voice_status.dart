import 'package:freezed_annotation/freezed_annotation.dart';

part 'owner_voice_status.freezed.dart';
part 'owner_voice_status.g.dart';

@freezed
class OwnerVoiceStatus with _$OwnerVoiceStatus {
  const factory OwnerVoiceStatus({
    required bool enrolled,
    String? speakerId,
    DateTime? enrolledAt,
  }) = _OwnerVoiceStatus;

  factory OwnerVoiceStatus.fromJson(Map<String, dynamic> json) =>
      _$OwnerVoiceStatusFromJson(json);
}
