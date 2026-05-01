import 'package:freezed_annotation/freezed_annotation.dart';

part 'scope_descriptor.freezed.dart';
part 'scope_descriptor.g.dart';

@freezed
class ScopeDescriptor with _$ScopeDescriptor {
  const factory ScopeDescriptor({
    required String key,
    required String label,
    required String description,
  }) = _ScopeDescriptor;

  factory ScopeDescriptor.fromJson(Map<String, dynamic> json) =>
      _$ScopeDescriptorFromJson(json);
}
