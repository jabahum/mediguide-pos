// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drug_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DrugClass _$DrugClassFromJson(Map<String, dynamic> json) => _DrugClass(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
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

Map<String, dynamic> _$DrugClassToJson(
  _DrugClass instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
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

_CreateDrugClassRequest _$CreateDrugClassRequestFromJson(
  Map<String, dynamic> json,
) => _CreateDrugClassRequest(
  name: json['name'] as String,
  description: json['description'] as String?,
  sortOrder: (json['sort_order'] as num?)?.toInt(),
  status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
);

Map<String, dynamic> _$CreateDrugClassRequestToJson(
  _CreateDrugClassRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  if (instance.description case final value?) 'description': value,
  if (instance.sortOrder case final value?) 'sort_order': value,
  if (_$StatusEnumMap[instance.status] case final value?) 'status': value,
};
