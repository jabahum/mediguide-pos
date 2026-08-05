// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drug_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DrugTag _$DrugTagFromJson(Map<String, dynamic> json) => _DrugTag(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
  color: json['color'] as String? ?? '',
  tagCategory: json['tag_category'] as String? ?? '',
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  status:
      $enumDecodeNullable(
        _$StatusEnumMap,
        json['status'],
        unknownValue: Status.unknown,
      ) ??
      Status.active,
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$DrugTagToJson(_DrugTag instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'color': instance.color,
  'tag_category': instance.tagCategory,
  'sort_order': instance.sortOrder,
  'status': _$StatusEnumMap[instance.status]!,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

const _$StatusEnumMap = {
  Status.active: 'active',
  Status.inactive: 'inactive',
  Status.unknown: 'unknown',
};

_CreateDrugTagRequest _$CreateDrugTagRequestFromJson(
  Map<String, dynamic> json,
) => _CreateDrugTagRequest(
  name: json['name'] as String,
  description: json['description'] as String?,
  color: json['color'] as String?,
  tagCategory: json['tag_category'] as String?,
  sortOrder: (json['sort_order'] as num?)?.toInt(),
  status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
);

Map<String, dynamic> _$CreateDrugTagRequestToJson(
  _CreateDrugTagRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  if (instance.description case final value?) 'description': value,
  if (instance.color case final value?) 'color': value,
  if (instance.tagCategory case final value?) 'tag_category': value,
  if (instance.sortOrder case final value?) 'sort_order': value,
  if (_$StatusEnumMap[instance.status] case final value?) 'status': value,
};
