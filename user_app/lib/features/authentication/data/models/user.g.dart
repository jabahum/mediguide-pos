// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  email: json['email'] as String? ?? '',
  emailVisibility: json['email_visibility'] as bool? ?? false,
  verified: json['verified'] as bool? ?? false,
  phone: json['phone'] as String? ?? '',
  alternativePhone: json['alternative_phone'] as String? ?? '',
  address: json['address'] as String? ?? '',
  city: json['city'] as String? ?? '',
  state: json['state'] as String? ?? '',
  country: json['country'] as String? ?? '',
  postalCode: json['postal_code'] as String? ?? '',
  licenseNumber: json['license_number'] as String? ?? '',
  organization: json['organization'] as String? ?? '',
  department: json['department'] as String? ?? '',
  jobTitle: json['job_title'] as String? ?? '',
  timezone: json['timezone'] as String? ?? '',
  notes: json['notes'] as String? ?? '',
  avatar: json['avatar'] as String? ?? '',
  role: _roleFromJson(json['role']),
  status: _statusFromJson(json['status']),
  specialization: json['specialization'] as String? ?? '',
  preferredLanguage: _languageFromJson(json['preferred_language']),
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'email_visibility': instance.emailVisibility,
  'verified': instance.verified,
  'phone': instance.phone,
  'alternative_phone': instance.alternativePhone,
  'address': instance.address,
  'city': instance.city,
  'state': instance.state,
  'country': instance.country,
  'postal_code': instance.postalCode,
  'license_number': instance.licenseNumber,
  'organization': instance.organization,
  'department': instance.department,
  'job_title': instance.jobTitle,
  'timezone': instance.timezone,
  'notes': instance.notes,
  'avatar': instance.avatar,
  'role': _roleToJson(instance.role),
  'status': _statusToJson(instance.status),
  'specialization': instance.specialization,
  'preferred_language': _languageToJson(instance.preferredLanguage),
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_UserUpdateRequest _$UserUpdateRequestFromJson(Map<String, dynamic> json) =>
    _UserUpdateRequest(
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      alternativePhone: json['alternative_phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      organization: json['organization'] as String?,
      department: json['department'] as String?,
      jobTitle: json['job_title'] as String?,
      specialization: json['specialization'] as String?,
      preferredLanguage: json['preferred_language'] as String?,
    );

Map<String, dynamic> _$UserUpdateRequestToJson(
  _UserUpdateRequest instance,
) => <String, dynamic>{
  if (instance.name case final value?) 'name': value,
  if (instance.phone case final value?) 'phone': value,
  if (instance.alternativePhone case final value?) 'alternative_phone': value,
  if (instance.address case final value?) 'address': value,
  if (instance.city case final value?) 'city': value,
  if (instance.state case final value?) 'state': value,
  if (instance.country case final value?) 'country': value,
  if (instance.postalCode case final value?) 'postal_code': value,
  if (instance.organization case final value?) 'organization': value,
  if (instance.department case final value?) 'department': value,
  if (instance.jobTitle case final value?) 'job_title': value,
  if (instance.specialization case final value?) 'specialization': value,
  if (instance.preferredLanguage case final value?) 'preferred_language': value,
};
