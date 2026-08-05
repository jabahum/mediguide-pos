// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consultant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Consultant _$ConsultantFromJson(Map<String, dynamic> json) => _Consultant(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  email: json['email'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  alternativePhone: json['alternative_phone'] as String? ?? '',
  profilePicture: json['profile_picture'] as String? ?? '',
  avatar: json['avatar'] as String? ?? '',
  specialtyValue: json['specialty'] as String? ?? '',
  licenseNumber: json['license_number'] as String? ?? '',
  yearsOfExperience: (json['years_of_experience'] as num?)?.toDouble() ?? 0,
  qualifications:
      (json['qualifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  certifications: json['certifications'] as String? ?? '',
  address: json['address'] as String? ?? '',
  city: json['city'] as String? ?? '',
  region: json['region'] as String? ?? '',
  country: json['country'] as String? ?? '',
  postalCode: json['postal_code'] as String? ?? '',
  organization: json['organization'] as String? ?? '',
  department: json['department'] as String? ?? '',
  preferredLanguageValue: json['preferred_language'] as String? ?? '',
  timezone: json['timezone'] as String? ?? '',
  availability: json['availability'] as Map<String, dynamic>? ?? const {},
  consultationTypeValues:
      (json['consultation_types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  statusValue: json['status'] as String? ?? 'inactive',
  isVerified: json['is_verified'] as bool? ?? false,
  rating: (json['rating'] as num?)?.toDouble() ?? 0,
  totalConsultations: (json['total_consultations'] as num?)?.toInt() ?? 0,
  notes: json['notes'] as String? ?? '',
  usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
  userId: json['user_id'] as String?,
  userData: json['user'] as Map<String, dynamic>?,
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$ConsultantToJson(
  _Consultant instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'alternative_phone': instance.alternativePhone,
  'profile_picture': instance.profilePicture,
  'avatar': instance.avatar,
  'specialty': instance.specialtyValue,
  'license_number': instance.licenseNumber,
  'years_of_experience': instance.yearsOfExperience,
  'qualifications': instance.qualifications,
  'certifications': instance.certifications,
  'address': instance.address,
  'city': instance.city,
  'region': instance.region,
  'country': instance.country,
  'postal_code': instance.postalCode,
  'organization': instance.organization,
  'department': instance.department,
  'preferred_language': instance.preferredLanguageValue,
  'timezone': instance.timezone,
  'availability': instance.availability,
  'consultation_types': instance.consultationTypeValues,
  'status': instance.statusValue,
  'is_verified': instance.isVerified,
  'rating': instance.rating,
  'total_consultations': instance.totalConsultations,
  'notes': instance.notes,
  'usage_count': instance.usageCount,
  'user_id': instance.userId,
  'user': instance.userData,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_ConsultantRequest _$ConsultantRequestFromJson(Map<String, dynamic> json) =>
    _ConsultantRequest(
      userId: json['user_id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      alternativePhone: json['alternative_phone'] as String?,
      specialty: json['specialty'] as String?,
      licenseNumber: json['license_number'] as String?,
      yearsOfExperience: (json['years_of_experience'] as num?)?.toDouble(),
      qualifications: (json['qualifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      certifications: json['certifications'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      organization: json['organization'] as String?,
      department: json['department'] as String?,
      preferredLanguage: json['preferred_language'] as String?,
      timezone: json['timezone'] as String?,
      availability: json['availability'] as Map<String, dynamic>?,
      consultationTypes: (json['consultation_types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: json['status'] as String?,
      isVerified: json['is_verified'] as bool?,
      rating: (json['rating'] as num?)?.toDouble(),
      totalConsultations: (json['total_consultations'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ConsultantRequestToJson(
  _ConsultantRequest instance,
) => <String, dynamic>{
  if (instance.userId case final value?) 'user_id': value,
  if (instance.name case final value?) 'name': value,
  if (instance.email case final value?) 'email': value,
  if (instance.phone case final value?) 'phone': value,
  if (instance.alternativePhone case final value?) 'alternative_phone': value,
  if (instance.specialty case final value?) 'specialty': value,
  if (instance.licenseNumber case final value?) 'license_number': value,
  if (instance.yearsOfExperience case final value?)
    'years_of_experience': value,
  if (instance.qualifications case final value?) 'qualifications': value,
  if (instance.certifications case final value?) 'certifications': value,
  if (instance.address case final value?) 'address': value,
  if (instance.city case final value?) 'city': value,
  if (instance.region case final value?) 'region': value,
  if (instance.country case final value?) 'country': value,
  if (instance.postalCode case final value?) 'postal_code': value,
  if (instance.organization case final value?) 'organization': value,
  if (instance.department case final value?) 'department': value,
  if (instance.preferredLanguage case final value?) 'preferred_language': value,
  if (instance.timezone case final value?) 'timezone': value,
  if (instance.availability case final value?) 'availability': value,
  if (instance.consultationTypes case final value?) 'consultation_types': value,
  if (instance.status case final value?) 'status': value,
  if (instance.isVerified case final value?) 'is_verified': value,
  if (instance.rating case final value?) 'rating': value,
  if (instance.totalConsultations case final value?)
    'total_consultations': value,
  if (instance.notes case final value?) 'notes': value,
};
