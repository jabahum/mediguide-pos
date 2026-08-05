import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'role.freezed.dart';
part 'role.g.dart';

@freezed
abstract class Role with _$Role {
  const factory Role({
    required String id,
    @Default('') String name,
    @Default('') String key,
    @Default('') String description,
    @Default({}) Map<String, dynamic> permissions,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Role;
  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);
}
