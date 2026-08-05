// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AbbreviationUsageLog _$AbbreviationUsageLogFromJson(
  Map<String, dynamic> json,
) => _AbbreviationUsageLog(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  abbreviationId: json['abbreviation_id'] as String,
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$AbbreviationUsageLogToJson(
  _AbbreviationUsageLog instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'abbreviation_id': instance.abbreviationId,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_AiUsageLog _$AiUsageLogFromJson(Map<String, dynamic> json) => _AiUsageLog(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$AiUsageLogToJson(
  _AiUsageLog instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_ConsultantUsageLog _$ConsultantUsageLogFromJson(Map<String, dynamic> json) =>
    _ConsultantUsageLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      consultantId: json['consultant_id'] as String,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$ConsultantUsageLogToJson(
  _ConsultantUsageLog instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'consultant_id': instance.consultantId,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_DrugUsageLog _$DrugUsageLogFromJson(Map<String, dynamic> json) =>
    _DrugUsageLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      drugId: json['drug_id'] as String,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$DrugUsageLogToJson(
  _DrugUsageLog instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'drug_id': instance.drugId,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_GuidelineUsageLog _$GuidelineUsageLogFromJson(Map<String, dynamic> json) =>
    _GuidelineUsageLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      guidelineId: json['guideline_id'] as String,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$GuidelineUsageLogToJson(
  _GuidelineUsageLog instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'guideline_id': instance.guidelineId,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_CalculatorUsageLog _$CalculatorUsageLogFromJson(Map<String, dynamic> json) =>
    _CalculatorUsageLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      calculatorId: json['calculator_id'] as String,
      sessionStart: DateTime.parse(json['session_start'] as String),
      sessionEnd: json['session_end'] == null
          ? null
          : DateTime.parse(json['session_end'] as String),
      calculatorTypeValue: json['calculator_type'] as String? ?? 'calculator',
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$CalculatorUsageLogToJson(
  _CalculatorUsageLog instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'calculator_id': instance.calculatorId,
  'session_start': instance.sessionStart.toIso8601String(),
  'session_end': instance.sessionEnd?.toIso8601String(),
  'calculator_type': instance.calculatorTypeValue,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_CalculatorUsageRequest _$CalculatorUsageRequestFromJson(
  Map<String, dynamic> json,
) => _CalculatorUsageRequest(
  calculatorId: json['calculator_id'] as String?,
  sessionStart: json['session_start'] == null
      ? null
      : DateTime.parse(json['session_start'] as String),
  sessionEnd: json['session_end'] == null
      ? null
      : DateTime.parse(json['session_end'] as String),
  calculatorType: json['calculator_type'] as String?,
);

Map<String, dynamic> _$CalculatorUsageRequestToJson(
  _CalculatorUsageRequest instance,
) => <String, dynamic>{
  if (instance.calculatorId case final value?) 'calculator_id': value,
  if (instance.sessionStart?.toIso8601String() case final value?)
    'session_start': value,
  if (instance.sessionEnd?.toIso8601String() case final value?)
    'session_end': value,
  if (instance.calculatorType case final value?) 'calculator_type': value,
};
