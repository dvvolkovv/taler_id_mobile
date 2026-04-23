import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_summary.freezed.dart';
part 'channel_summary.g.dart';

@freezed
class ChannelSummary with _$ChannelSummary {
  const factory ChannelSummary({
    required String id,
    String? name,
    String? description,
    String? avatarUrl,
    @Default(0) int subscribersCount,
    @Default(false) bool isSubscribed,
  }) = _ChannelSummary;

  factory ChannelSummary.fromJson(Map<String, dynamic> json) =>
      _$ChannelSummaryFromJson(json);
}
