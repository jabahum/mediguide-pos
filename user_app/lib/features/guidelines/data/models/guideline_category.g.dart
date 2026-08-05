// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guideline_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuidelineCategory _$GuidelineCategoryFromJson(Map<String, dynamic> json) =>
    _GuidelineCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      color: json['color'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      parentCategoryId: json['parent_category_id'] as String?,
      parentName: json['parent_name'] as String?,
      status:
          $enumDecodeNullable(
            _$GuidelineCategoryStatusEnumMap,
            json['status'],
          ) ??
          GuidelineCategoryStatus.active,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$GuidelineCategoryToJson(
  _GuidelineCategory instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'description': instance.description,
  'sort_order': instance.sortOrder,
  'color': instance.color,
  'icon': instance.icon,
  'parent_category_id': instance.parentCategoryId,
  'parent_name': instance.parentName,
  'status': _$GuidelineCategoryStatusEnumMap[instance.status]!,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

const _$GuidelineCategoryStatusEnumMap = {
  GuidelineCategoryStatus.active: 'active',
  GuidelineCategoryStatus.inactive: 'inactive',
  GuidelineCategoryStatus.unknown: 'unknown',
};

_CreateGuidelineCategoryRequest _$CreateGuidelineCategoryRequestFromJson(
  Map<String, dynamic> json,
) => _CreateGuidelineCategoryRequest(
  name: json['name'] as String,
  slug: json['slug'] as String?,
  description: json['description'] as String?,
  sortOrder: (json['sort_order'] as num?)?.toInt(),
  status: $enumDecodeNullable(_$GuidelineCategoryStatusEnumMap, json['status']),
  color: json['color'] as String?,
  icon: json['icon'] as String?,
  parentCategoryId: json['parent_category_id'] as String?,
);

Map<String, dynamic> _$CreateGuidelineCategoryRequestToJson(
  _CreateGuidelineCategoryRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  if (instance.slug case final value?) 'slug': value,
  if (instance.description case final value?) 'description': value,
  if (instance.sortOrder case final value?) 'sort_order': value,
  if (_$GuidelineCategoryStatusEnumMap[instance.status] case final value?)
    'status': value,
  if (instance.color case final value?) 'color': value,
  if (instance.icon case final value?) 'icon': value,
  if (instance.parentCategoryId case final value?) 'parent_category_id': value,
};
