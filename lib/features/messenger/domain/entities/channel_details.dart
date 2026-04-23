import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_details.freezed.dart';
part 'channel_details.g.dart';

@freezed
class ChannelDetails with _$ChannelDetails {
  const factory ChannelDetails({
    required String id,
    String? name,
    String? description,
    String? avatarUrl,
    @Default(0) int subscribersCount,
    @Default(false) bool isSubscribed,
    String? myRole,
  }) = _ChannelDetails;

  factory ChannelDetails.fromJson(Map<String, dynamic> json) =>
      _$ChannelDetailsFromJson(json);
}
