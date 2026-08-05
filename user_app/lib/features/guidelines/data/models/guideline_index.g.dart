// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guideline_index.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuidelineIndex _$GuidelineIndexFromJson(Map<String, dynamic> json) =>
    _GuidelineIndex(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      parentTitle: json['parent_title'] as String?,
      order: (json['sort_order'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
      hasChildren: json['has_children'] as bool? ?? false,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$GuidelineIndexToJson(
  _GuidelineIndex instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'parent_id': instance.parentId,
  'parent_title': instance.parentTitle,
  'sort_order': instance.order,
  'level': instance.level,
  'has_children': instance.hasChildren,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_CreateGuidelineIndexRequest _$CreateGuidelineIndexRequestFromJson(
  Map<String, dynamic> json,
) => _CreateGuidelineIndexRequest(
  title: json['title'] as String,
  description: json['description'] as String?,
  parentId: json['parent_id'] as String?,
  sortOrder: (json['sort_order'] as num?)?.toInt(),
  level: (json['level'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateGuidelineIndexRequestToJson(
  _CreateGuidelineIndexRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  if (instance.description case final value?) 'description': value,
  if (instance.parentId case final value?) 'parent_id': value,
  if (instance.sortOrder case final value?) 'sort_order': value,
  if (instance.level case final value?) 'level': value,
};
