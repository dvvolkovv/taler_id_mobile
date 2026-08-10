import 'package:freezed_annotation/freezed_annotation.dart';

part 'forwarded_from_entity.freezed.dart';
part 'forwarded_from_entity.g.dart';

/// Атрибуция пересылки — «Переслано от X».
///
/// [name] — снимок имени на момент пересылки, а не текущее имя автора: он мог
/// переименоваться или удалиться, а подпись должна остаться той, что видел
/// пересылавший.
///
/// [messageId] — id оригинала. Перейти по нему можно только если пользователь
/// состоит в исходной беседе, поэтому клиент им не пользуется для навигации.
@freezed
class ForwardedFromEntity with _$ForwardedFromEntity {
  const factory ForwardedFromEntity({
    String? userId,
    String? name,
    String? messageId,
  }) = _ForwardedFromEntity;

  factory ForwardedFromEntity.fromJson(Map<String, dynamic> json) =>
      _$ForwardedFromEntityFromJson(json);
}
