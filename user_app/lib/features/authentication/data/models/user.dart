import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/authentication/data/models/user_enums.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const User._();
  const factory User({
    required String id,
    @Default('') String name,
    @Default('') String email,
    @JsonKey(name: 'email_visibility') @Default(false) bool emailVisibility,
    @Default(false) bool verified,
    @Default('') String phone,
    @JsonKey(name: 'alternative_phone') @Default('') String alternativePhone,
    @Default('') String address,
    @Default('') String city,
    @Default('') String state,
    @Default('') String country,
    @JsonKey(name: 'postal_code') @Default('') String postalCode,
    @JsonKey(name: 'license_number') @Default('') String licenseNumber,
    @Default('') String organization,
    @Default('') String department,
    @JsonKey(name: 'job_title') @Default('') String jobTitle,
    @Default('') String timezone,
    @Default('') String notes,
    @Default('') String avatar,
    @JsonKey(fromJson: _roleFromJson, toJson: _roleToJson) UserRole? role,
    @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
    UserStatus? status,
    @Default('') String specialization,
    @JsonKey(
      name: 'preferred_language',
      fromJson: _languageFromJson,
      toJson: _languageToJson,
    )
    PreferredLanguage? preferredLanguage,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _User;
  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(_normalizeUser(json));
}

Map<String, dynamic> _normalizeUser(Map<String, dynamic> json) {
  final roles = json['roles'];
  final role =
      json['role'] ??
      (roles is List && roles.isNotEmpty && roles.first is Map
          ? ((roles.first as Map)['role_key'] ?? (roles.first as Map)['name'])
          : null);
  return {
    ...json,
    'role': role,
    'email_visibility':
        json['email_visibility'] ?? json['emailVisibility'] ?? false,
    'alternative_phone':
        json['alternative_phone'] ?? json['alternativePhone'] ?? '',
    'postal_code': json['postal_code'] ?? json['postalCode'] ?? '',
    'license_number': json['license_number'] ?? json['licenseNumber'] ?? '',
    'job_title': json['job_title'] ?? json['jobTitle'] ?? '',
    'preferred_language':
        json['preferred_language'] ?? json['preferredLanguage'],
    'created_at': json['created_at'] ?? json['created'],
    'updated_at': json['updated_at'] ?? json['updated'],
  };
}

T? _enumValue<T extends Enum>(List<T> values, Object? raw) {
  final value = raw?.toString().replaceAll('-', '_').toLowerCase();
  if (value == null || value.isEmpty) return null;
  for (final item in values) {
    final name = item.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );
    if (name == value || item.name.toLowerCase() == value.replaceAll('_', '')) {
      return item;
    }
  }
  return null;
}

UserRole? _roleFromJson(Object? value) => value?.toString() == 'clinician'
    ? UserRole.healthcareProvider
    : _enumValue(UserRole.values, value);
String? _roleToJson(UserRole? value) => value?.name;
UserStatus? _statusFromJson(Object? value) =>
    _enumValue(UserStatus.values, value);
String? _statusToJson(UserStatus? value) => value?.name;
PreferredLanguage? _languageFromJson(Object? value) => value?.toString() == 'en'
    ? PreferredLanguage.english
    : _enumValue(PreferredLanguage.values, value);
String? _languageToJson(PreferredLanguage? value) => value?.name;

@freezed
abstract class UserUpdateRequest with _$UserUpdateRequest {
  @JsonSerializable(includeIfNull: false)
  const factory UserUpdateRequest({
    String? name,
    String? phone,
    @JsonKey(name: 'alternative_phone') String? alternativePhone,
    String? address,
    String? city,
    String? state,
    String? country,
    @JsonKey(name: 'postal_code') String? postalCode,
    String? organization,
    String? department,
    @JsonKey(name: 'job_title') String? jobTitle,
    String? specialization,
    @JsonKey(name: 'preferred_language') String? preferredLanguage,
  }) = _UserUpdateRequest;
  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$UserUpdateRequestFromJson(json);
}
