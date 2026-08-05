// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Role _$RoleFromJson(Map<String, dynamic> json) => _Role(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  key: json['key'] as String? ?? '',
  description: json['description'] as String? ?? '',
  permissions: json['permissions'] as Map<String, dynamic>? ?? const {},
  isActive: json['is_active'] as bool? ?? true,
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$RoleToJson(_Role instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'key': instance.key,
  'description': instance.description,
  'permissions': instance.permissions,
  'is_active': instance.isActive,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};
