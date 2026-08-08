import 'package:freezed_annotation/freezed_annotation.dart';

part 'pinned_preview_entity.freezed.dart';
part 'pinned_preview_entity.g.dart';

/// Preview of the top pinned message — arrives in the conversation payload
/// so the pinned bar can render before the full pin list has loaded.
@freezed
class PinnedPreviewEntity with _$PinnedPreviewEntity {
  const factory PinnedPreviewEntity({
    required String id,
    @Default('') String content,
    String? senderName,
    DateTime? sentAt,
    DateTime? pinnedAt,
  }) = _PinnedPreviewEntity;

  factory PinnedPreviewEntity.fromJson(Map<String, dynamic> json) =>
      _$PinnedPreviewEntityFromJson(json);
}
