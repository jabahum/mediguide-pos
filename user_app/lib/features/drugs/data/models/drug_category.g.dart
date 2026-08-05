// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drug_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DrugCategory _$DrugCategoryFromJson(Map<String, dynamic> json) =>
    _DrugCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      status:
          $enumDecodeNullable(
            _$StatusEnumMap,
            json['status'],
            unknownValue: Status.unknown,
          ) ??
          Status.active,
      parentCategoryId: json['parent_category_id'] as String?,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$DrugCategoryToJson(
  _DrugCategory instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'color': instance.color,
  'icon': instance.icon,
  'sort_order': instance.sortOrder,
  'status': _$StatusEnumMap[instance.status]!,
  'parent_category_id': instance.parentCategoryId,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

const _$StatusEnumMap = {
  Status.active: 'active',
  Status.inactive: 'inactive',
  Status.unknown: 'unknown',
};

_CreateDrugCategoryRequest _$CreateDrugCategoryRequestFromJson(
  Map<String, dynamic> json,
) => _CreateDrugCategoryRequest(
  name: json['name'] as String,
  description: json['description'] as String?,
  color: json['color'] as String?,
  icon: json['icon'] as String?,
  sortOrder: (json['sort_order'] as num?)?.toInt(),
  status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
  parentCategoryId: json['parent_category_id'] as String?,
);

Map<String, dynamic> _$CreateDrugCategoryRequestToJson(
  _CreateDrugCategoryRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  if (instance.description case final value?) 'description': value,
  if (instance.color case final value?) 'color': value,
  if (instance.icon case final value?) 'icon': value,
  if (instance.sortOrder case final value?) 'sort_order': value,
  if (_$StatusEnumMap[instance.status] case final value?) 'status': value,
  if (instance.parentCategoryId case final value?) 'parent_category_id': value,
};
