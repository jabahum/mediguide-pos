// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'facility_usage_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FacilityUsageLog _$FacilityUsageLogFromJson(Map<String, dynamic> json) =>
    _FacilityUsageLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      facilityId: json['facility_id'] as String,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$FacilityUsageLogToJson(
  _FacilityUsageLog instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'facility_id': instance.facilityId,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};
