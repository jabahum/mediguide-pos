// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Calculator _$CalculatorFromJson(Map<String, dynamic> json) => _Calculator(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
  icon: json['icon'] as String? ?? '',
  color: json['color'] as String? ?? '',
  backgroundColor: json['background_color'] as String? ?? '',
  appFile: json['app_file'] as String? ?? '',
  version: json['version'] as String? ?? '',
  addedByUserId: json['added_by_user_id'] as String?,
  typeValue: json['type'] as String? ?? 'calculator',
  statusValue: json['status'] as String? ?? 'draft',
  usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
  featured: json['featured'] as bool? ?? false,
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$CalculatorToJson(
  _Calculator instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'icon': instance.icon,
  'color': instance.color,
  'background_color': instance.backgroundColor,
  'app_file': instance.appFile,
  'version': instance.version,
  'added_by_user_id': instance.addedByUserId,
  'type': instance.typeValue,
  'status': instance.statusValue,
  'usage_count': instance.usageCount,
  'featured': instance.featured,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_CalculatorRequest _$CalculatorRequestFromJson(Map<String, dynamic> json) =>
    _CalculatorRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      backgroundColor: json['background_color'] as String?,
      appFile: json['app_file'] as Map<String, dynamic>?,
      version: json['version'] as String?,
      addedByUserId: json['added_by_user_id'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      featured: json['featured'] as bool?,
    );

Map<String, dynamic> _$CalculatorRequestToJson(_CalculatorRequest instance) =>
    <String, dynamic>{
      if (instance.name case final value?) 'name': value,
      if (instance.description case final value?) 'description': value,
      if (instance.icon case final value?) 'icon': value,
      if (instance.color case final value?) 'color': value,
      if (instance.backgroundColor case final value?) 'background_color': value,
      if (instance.appFile case final value?) 'app_file': value,
      if (instance.version case final value?) 'version': value,
      if (instance.addedByUserId case final value?) 'added_by_user_id': value,
      if (instance.type case final value?) 'type': value,
      if (instance.status case final value?) 'status': value,
      if (instance.featured case final value?) 'featured': value,
    };
