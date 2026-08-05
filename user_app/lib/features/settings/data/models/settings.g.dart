// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Settings _$SettingsFromJson(Map<String, dynamic> json) => _Settings(
  id: json['id'] as String,
  key: json['key'] as String,
  value: json['value'],
  category: json['category'] as String? ?? '',
  description: json['description'] as String? ?? '',
  isPublic: json['is_public'] as bool? ?? false,
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$SettingsToJson(_Settings instance) => <String, dynamic>{
  'id': instance.id,
  'key': instance.key,
  'value': instance.value,
  'category': instance.category,
  'description': instance.description,
  'is_public': instance.isPublic,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_SettingsRequest _$SettingsRequestFromJson(Map<String, dynamic> json) =>
    _SettingsRequest(
      key: json['key'] as String?,
      value: json['value'],
      category: json['category'] as String?,
      description: json['description'] as String?,
      isPublic: json['is_public'] as bool?,
    );

Map<String, dynamic> _$SettingsRequestToJson(_SettingsRequest instance) =>
    <String, dynamic>{
      if (instance.key case final value?) 'key': value,
      if (instance.value case final value?) 'value': value,
      if (instance.category case final value?) 'category': value,
      if (instance.description case final value?) 'description': value,
      if (instance.isPublic case final value?) 'is_public': value,
    };
