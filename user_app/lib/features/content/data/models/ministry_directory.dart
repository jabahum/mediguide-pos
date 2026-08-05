import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/content/data/models/ministry_directory_enums.dart';
import 'package:user_app/features/facilities/data/models/district.dart';
import 'package:user_app/features/facilities/data/models/region.dart';

part 'ministry_directory.freezed.dart';
part 'ministry_directory.g.dart';

@freezed
abstract class MinistryDirectory with _$MinistryDirectory {
  const MinistryDirectory._();

  const factory MinistryDirectory({
    required String id,
    @Default('') String name,
    @Default('') String title,
    @JsonKey(name: 'ministry') @Default('') String ministryValue,
    @Default('') String department,
    @Default('') String phone,
    @JsonKey(name: 'alternative_phone') @Default('') String alternativePhone,
    @Default('') String email,
    @JsonKey(name: 'office_address') @Default('') String officeAddress,
    @JsonKey(name: 'priority_level') @Default(0) int priorityLevel,
    @JsonKey(name: 'availability_hours') @Default('') String availabilityHours,
    @Default('') String specialization,
    @JsonKey(name: 'status') @Default('inactive') String statusValue,
    @Default('') String notes,
    @JsonKey(name: 'district_id') String? districtId,
    @JsonKey(name: 'district_name') @Default('') String districtName,
    @JsonKey(name: 'region_id') String? regionId,
    @JsonKey(name: 'region_name') @Default('') String regionName,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _MinistryDirectory;

  factory MinistryDirectory.fromJson(Map<String, dynamic> json) =>
      _$MinistryDirectoryFromJson(json);

  Ministry get ministry => Ministry.values.firstWhere(
    (value) => value.label == ministryValue,
    orElse: () => Ministry.other,
  );

  MinistryDirectoryStatus get status =>
      MinistryDirectoryStatus.values.firstWhere(
        (value) => value.name == statusValue,
        orElse: () => MinistryDirectoryStatus.inactive,
      );

  District? get district =>
      districtId?.isNotEmpty == true || districtName.isNotEmpty
      ? District(id: districtId ?? '', name: districtName)
      : null;
  Region? get region => regionId?.isNotEmpty == true || regionName.isNotEmpty
      ? Region(id: regionId ?? '', name: regionName)
      : null;
  String get displayName => '$name - $title';
  String get contactInfo => [
    phone,
    if (alternativePhone.isNotEmpty) alternativePhone,
    if (email.isNotEmpty) email,
  ].where((value) => value.isNotEmpty).join(' • ');
  String get locationString =>
      [districtName, regionName].where((value) => value.isNotEmpty).join(', ');
  bool get isEmergencyContact => priorityLevel == 1;
  bool get isAvailable => status == MinistryDirectoryStatus.active;
}

@freezed
abstract class MinistryDirectoryRequest with _$MinistryDirectoryRequest {
  @JsonSerializable(includeIfNull: false)
  const factory MinistryDirectoryRequest({
    String? name,
    String? title,
    String? ministry,
    String? department,
    String? phone,
    @JsonKey(name: 'alternative_phone') String? alternativePhone,
    String? email,
    @JsonKey(name: 'office_address') String? officeAddress,
    @JsonKey(name: 'priority_level') int? priorityLevel,
    @JsonKey(name: 'availability_hours') String? availabilityHours,
    String? specialization,
    String? status,
    String? notes,
    @JsonKey(name: 'district_id') String? districtId,
    @JsonKey(name: 'region_id') String? regionId,
  }) = _MinistryDirectoryRequest;

  factory MinistryDirectoryRequest.fromJson(Map<String, dynamic> json) =>
      _$MinistryDirectoryRequestFromJson(json);
}
