import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/authentication/data/models/user_enums.dart';
import 'package:user_app/features/consultants/data/models/consultant_enums.dart';

part 'consultant.freezed.dart';
part 'consultant.g.dart';

@Freezed(makeCollectionsUnmodifiable: true)
abstract class Consultant with _$Consultant {
  const Consultant._();
  @JsonSerializable(explicitToJson: true)
  const factory Consultant({
    required String id,
    @Default('') String name,
    @Default('') String email,
    @Default('') String phone,
    @JsonKey(name: 'alternative_phone') @Default('') String alternativePhone,
    @JsonKey(name: 'profile_picture') @Default('') String profilePicture,
    @Default('') String avatar,
    @JsonKey(name: 'specialty') @Default('') String specialtyValue,
    @JsonKey(name: 'license_number') @Default('') String licenseNumber,
    @JsonKey(name: 'years_of_experience') @Default(0) double yearsOfExperience,
    @Default([]) List<String> qualifications,
    @Default('') String certifications,
    @Default('') String address,
    @Default('') String city,
    @Default('') String region,
    @Default('') String country,
    @JsonKey(name: 'postal_code') @Default('') String postalCode,
    @Default('') String organization,
    @Default('') String department,
    @JsonKey(name: 'preferred_language')
    @Default('')
    String preferredLanguageValue,
    @Default('') String timezone,
    @Default({}) Map<String, dynamic> availability,
    @JsonKey(name: 'consultation_types')
    @Default([])
    List<String> consultationTypeValues,
    @JsonKey(name: 'status') @Default('inactive') String statusValue,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @Default(0) double rating,
    @JsonKey(name: 'total_consultations') @Default(0) int totalConsultations,
    @Default('') String notes,
    @JsonKey(name: 'usage_count') @Default(0) int usageCount,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'user') Map<String, dynamic>? userData,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Consultant;
  factory Consultant.fromJson(Map<String, dynamic> json) =>
      _$ConsultantFromJson(_normalizeConsultant(json));
  ConsultantSpecialty? get specialty => _enumByLabel(
    ConsultantSpecialty.values,
    specialtyValue,
    (value) => value.label,
  );
  ConsultantStatus get status =>
      _enumByLabel(
        ConsultantStatus.values,
        statusValue,
        (value) => value.label,
      ) ??
      ConsultantStatus.inactive;
  List<ConsultantQualification> get qualificationEnums => qualifications
      .map(
        (value) => _enumByLabel(
          ConsultantQualification.values,
          value,
          (item) => item.label,
        ),
      )
      .whereType<ConsultantQualification>()
      .toList(growable: false);
  List<ConsultationType> get consultationTypes => consultationTypeValues
      .map(
        (value) =>
            _enumByLabel(ConsultationType.values, value, (item) => item.label),
      )
      .whereType<ConsultationType>()
      .toList(growable: false);
  PreferredLanguage? get preferredLanguage => PreferredLanguage.values
      .where(
        (value) =>
            value.name.toLowerCase() == preferredLanguageValue.toLowerCase(),
      )
      .firstOrNull;
  User? get userAccount => userData == null ? null : User(userData!);
}

Map<String, dynamic> _normalizeConsultant(Map<String, dynamic> json) => {
  ...json,
  'profile_picture': _asset(json['profile_picture']),
  'avatar': _asset(json['avatar']),
};
String _asset(Object? value) => value is String
    ? value
    : value is Map
    ? (value['url'] ?? value['path'] ?? value['name'] ?? '').toString()
    : '';
T? _enumByLabel<T extends Enum>(
  List<T> values,
  String raw,
  String Function(T) label,
) {
  final normalized = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  for (final value in values) {
    if (value.name.toLowerCase() == raw.toLowerCase() ||
        label(value).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
            normalized) {
      return value;
    }
  }
  return null;
}

@freezed
abstract class ConsultantRequest with _$ConsultantRequest {
  @JsonSerializable(includeIfNull: false)
  const factory ConsultantRequest({
    @JsonKey(name: 'user_id') String? userId,
    String? name,
    String? email,
    String? phone,
    @JsonKey(name: 'alternative_phone') String? alternativePhone,
    String? specialty,
    @JsonKey(name: 'license_number') String? licenseNumber,
    @JsonKey(name: 'years_of_experience') double? yearsOfExperience,
    List<String>? qualifications,
    String? certifications,
    String? address,
    String? city,
    String? region,
    String? country,
    @JsonKey(name: 'postal_code') String? postalCode,
    String? organization,
    String? department,
    @JsonKey(name: 'preferred_language') String? preferredLanguage,
    String? timezone,
    Map<String, dynamic>? availability,
    @JsonKey(name: 'consultation_types') List<String>? consultationTypes,
    String? status,
    @JsonKey(name: 'is_verified') bool? isVerified,
    double? rating,
    @JsonKey(name: 'total_consultations') int? totalConsultations,
    String? notes,
  }) = _ConsultantRequest;
  factory ConsultantRequest.fromJson(Map<String, dynamic> json) =>
      _$ConsultantRequestFromJson(json);
}
