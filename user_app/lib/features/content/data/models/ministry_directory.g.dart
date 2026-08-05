// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ministry_directory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MinistryDirectory _$MinistryDirectoryFromJson(Map<String, dynamic> json) =>
    _MinistryDirectory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      ministryValue: json['ministry'] as String? ?? '',
      department: json['department'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      alternativePhone: json['alternative_phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      officeAddress: json['office_address'] as String? ?? '',
      priorityLevel: (json['priority_level'] as num?)?.toInt() ?? 0,
      availabilityHours: json['availability_hours'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      statusValue: json['status'] as String? ?? 'inactive',
      notes: json['notes'] as String? ?? '',
      districtId: json['district_id'] as String?,
      districtName: json['district_name'] as String? ?? '',
      regionId: json['region_id'] as String?,
      regionName: json['region_name'] as String? ?? '',
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$MinistryDirectoryToJson(
  _MinistryDirectory instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'title': instance.title,
  'ministry': instance.ministryValue,
  'department': instance.department,
  'phone': instance.phone,
  'alternative_phone': instance.alternativePhone,
  'email': instance.email,
  'office_address': instance.officeAddress,
  'priority_level': instance.priorityLevel,
  'availability_hours': instance.availabilityHours,
  'specialization': instance.specialization,
  'status': instance.statusValue,
  'notes': instance.notes,
  'district_id': instance.districtId,
  'district_name': instance.districtName,
  'region_id': instance.regionId,
  'region_name': instance.regionName,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_MinistryDirectoryRequest _$MinistryDirectoryRequestFromJson(
  Map<String, dynamic> json,
) => _MinistryDirectoryRequest(
  name: json['name'] as String?,
  title: json['title'] as String?,
  ministry: json['ministry'] as String?,
  department: json['department'] as String?,
  phone: json['phone'] as String?,
  alternativePhone: json['alternative_phone'] as String?,
  email: json['email'] as String?,
  officeAddress: json['office_address'] as String?,
  priorityLevel: (json['priority_level'] as num?)?.toInt(),
  availabilityHours: json['availability_hours'] as String?,
  specialization: json['specialization'] as String?,
  status: json['status'] as String?,
  notes: json['notes'] as String?,
  districtId: json['district_id'] as String?,
  regionId: json['region_id'] as String?,
);

Map<String, dynamic> _$MinistryDirectoryRequestToJson(
  _MinistryDirectoryRequest instance,
) => <String, dynamic>{
  if (instance.name case final value?) 'name': value,
  if (instance.title case final value?) 'title': value,
  if (instance.ministry case final value?) 'ministry': value,
  if (instance.department case final value?) 'department': value,
  if (instance.phone case final value?) 'phone': value,
  if (instance.alternativePhone case final value?) 'alternative_phone': value,
  if (instance.email case final value?) 'email': value,
  if (instance.officeAddress case final value?) 'office_address': value,
  if (instance.priorityLevel case final value?) 'priority_level': value,
  if (instance.availabilityHours case final value?) 'availability_hours': value,
  if (instance.specialization case final value?) 'specialization': value,
  if (instance.status case final value?) 'status': value,
  if (instance.notes case final value?) 'notes': value,
  if (instance.districtId case final value?) 'district_id': value,
  if (instance.regionId case final value?) 'region_id': value,
};
