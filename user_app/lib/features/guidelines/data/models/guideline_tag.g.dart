// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guideline_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuidelineTag _$GuidelineTagFromJson(Map<String, dynamic> json) =>
    _GuidelineTag(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$GuidelineTagToJson(
  _GuidelineTag instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_CreateGuidelineTagRequest _$CreateGuidelineTagRequestFromJson(
  Map<String, dynamic> json,
) => _CreateGuidelineTagRequest(
  name: json['name'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$CreateGuidelineTagRequestToJson(
  _CreateGuidelineTagRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  if (instance.description case final value?) 'description': value,
};
