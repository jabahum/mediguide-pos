// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LanguageModel _$LanguageModelFromJson(Map<String, dynamic> json) =>
    _LanguageModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['native_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      isDefault: json['is_default'] as bool? ?? false,
      translationsUrl: json['translations_url'] as String? ?? '',
      translations: json['translations'] as Map<String, dynamic>? ?? const {},
      version: (json['version'] as num?)?.toDouble() ?? 1,
      created: const NullableDateTimeConverter().fromJson(json['created']),
      updated: const NullableDateTimeConverter().fromJson(json['updated']),
    );

Map<String, dynamic> _$LanguageModelToJson(_LanguageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'native_name': instance.nativeName,
      'is_active': instance.isActive,
      'is_default': instance.isDefault,
      'translations_url': instance.translationsUrl,
      'translations': instance.translations,
      'version': instance.version,
      'created': const NullableDateTimeConverter().toJson(instance.created),
      'updated': const NullableDateTimeConverter().toJson(instance.updated),
    };
